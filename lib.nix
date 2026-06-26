{lib, utils, pkgs, ...}:
let inherit (lib) filter foldl' flip strings concatMap escapeShellArg fix
                  splitString pipe elem nameValuePair forEach match isList
                  substring isString mergeAttrsList singleton importJSON
                  splitStringBy listToAttrs mapAttrsToList zipListsWith
                  escapeURL split;
    inherit (lib.filesystem) listFilesRecursive;
    inherit (utils) escapeSystemdPath;
    inherit (pkgs) runCommandLocal;
in {
  _module.args.lib' = rec {
    apply = foldl' (f: x: f x);
    applyTo = flip apply;
    call = f: x: f x;
    optionalCall = p: f: x: if p x then f x else x;
    neg = f: x: !(f x);
    mkPipe = flip pipe;

    every' = neg (elem false);
    any' = elem true;
    everyF = fs: x: every' (map (apply [x]) fs);
    anyF = fs: x: any' (map (apply [x]) fs);
    compose = f: g: x: f (g x);

    attrEntry = nameValuePair;

    getAttrs' = names: attrs: mergeAttrsList (forEach names (name:
      if attrs ? ${name} then { ${name} = attrs.${name}; } else {}));

    identifierWords =
      let isWordBoundary = prev: next:
            let pattern =
                  "[[:lower:]][[:upper:]]|" +
                  "[[:alpha:]][[:digit:]]|" +
                  "[[:digit:]][[:alpha:]]";
            in match pattern (prev + next) != null;
      in mkPipe [
        (splitStringBy isWordBoundary true)
        (concatMap (strings.split "[^a-zA-Z0-9]+"))
        (filter (part: isString part && part != ""))
        (map strings.toLower)
      ];
    toKebabCase = mkPipe [identifierWords (strings.join "-")];
    toSnakeCase = mkPipe [identifierWords (strings.join "_")];

    importXML = path: importJSON "${runCommandLocal "importXML" {} ''
      ${pkgs.yq}/bin/xq . ${path} > "$out"
    ''}";

    escapeShellVars =
      mapAttrsToList (var: value: "${var}=${escapeShellArg value}");

    escapeSystemd = string:
      if strings.hasInfix "/" string then
        escapeSystemdPath string
      else
        pipe string [
          (splitString "-")
          (map (optionalCall (part: part != "") escapeSystemdPath))
          (strings.join "-")
        ];

    pathComponents = mkPipe [
      (strings.split "/+")
      (filter (part: isString part && part != ""))
    ];

    parseGVariantType =
      let parse = input:
            let current = substring 0 1 input;
                remaining = substring 1 (-1) input;
                parser = parsers.${current};
            in parser current remaining;
          token = character: constructor:
            attrEntry character (current: remaining: {
              type = current;
              inherit constructor remaining;
            });
          prefix = character: constructor:
            attrEntry character (current: remaining:
              let sub = parse remaining; in {
                type = character + sub.type;
                constructor = constructor sub.type;
                inherit (sub) remaining;
              });
          circumfix = characters: constructor:
            let character = substring 0 1 characters;
                terminator = substring 1 1 characters;
            in attrEntry character (current: remaining:
              (fix (recur: {subinput ? remaining,
                            subtypes ? "",
                            subconstructors ? []}:
                if substring 0 1 subinput == terminator then {
                  type = character + subtypes + terminator;
                  constructor = mkPipe [
                    (zipListsWith call subconstructors)
                    constructor
                  ];
                  remaining = substring 1 (-1) subinput;
                } else let sub = parse subinput; in recur {
                  subinput = sub.remaining;
                  subtypes = subtypes + sub.type;
                  subconstructors = subconstructors ++ [sub.constructor];
                }
              )) {});
          parsers = with lib.hm.gvariant; listToAttrs [
            (token "s" mkString)
            (token "b" mkBoolean)
            (token "y" mkUchar)
            (token "n" mkInt16)
            (token "q" mkUint16)
            (token "i" mkInt32)
            (token "u" mkUint32)
            (token "x" mkInt64)
            (token "t" mkUint64)
            (token "d" mkDouble)
            (token "v" mkVariant)
            (prefix "a" mkArray)
            (prefix "m" mkMaybe)
            (circumfix "{}" mkDictionaryEntry)
            (circumfix "()" mkTuple)
          ];
      in type: (parse type).constructor;

    coerceToGVariant = type: with lib.hm.gvariant;
      if type == null then mkValue else parseGVariantType type;

    coerceToList = optionalCall (neg isList) singleton;

    getGSettingsSchemas = mkPipe [
      (pkg: listFilesRecursive "${pkg}/share/gsettings-schemas")
      (filter (strings.hasSuffix ".gschema.xml"))
      (concatMap (path:
        let inherit (importXML path) schemalist;
        in coerceToList (schemalist.schema or [])))
    ];

    normalizeDConfPath = mkPipe [
      (strings.normalizePath)
      (strings.removePrefix "/")
      (strings.removeSuffix "/")
    ];

    mkFileUri = path: pipe path [
      (split "/+")
      (filter (item: isString item && item != ""))
      (map escapeURL)
      (strings.join "/")
      (path: "file:///${path}")
    ];
  };
}
