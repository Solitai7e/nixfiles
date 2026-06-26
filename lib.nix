{lib, utils, pkgs, ...}:
let inherit (lib) filter foldl' flip strings concatMap escapeShellArg last
                  splitString pipe elem nameValuePair forEach match isList
                  isString mergeAttrsList singleton importJSON splitStringBy
                  mapAttrsToList escapeURL split init updateManyAttrsByPath
                  length attrByPath escapeShellArgs makeLibraryPath isPath;
    inherit (lib.filesystem) listFilesRecursive;
    inherit (utils) escapeSystemdPath;
    inherit (pkgs) runCommandLocal stdenv;
    inherit (pkgs.writers) makeBinWriter;
in {
  _module.args.lib' = rec {
    apply = foldl' (f: x: f x);
    applyTo = flip apply;
    call = f: x: f x;
    callWith = x: f: f x;
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

    hasAttrAtPath = path: attrs:
      if length path == 1
        then attrs ? ${last path}
        else attrByPath (init path) {} attrs ? ${last path};

    removeAttrsByPath = attrs: paths:
      let updates = pipe paths [
        (filter (path: hasAttrAtPath path attrs))
        (map (path: {
          path = init path;
          update = subattrs: removeAttrs subattrs [(last path)];
        }))
      ];
      in updateManyAttrsByPath updates attrs;

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

    escapeShellVars' =
      mapAttrsToList (var: value: "${var}=${escapeShellArg value}");
    escapeShellVars =
      mkPipe [escapeShellVars (strings.join " ")];

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

    coerceToList = optionalCall (neg isList) singleton;

    mkFileUri = path: pipe path [
      (split "/+")
      (filter (item: isString item && item != ""))
      (map escapeURL)
      (strings.join "/")
      (path: "file:///${path}")
    ];
  };
}
