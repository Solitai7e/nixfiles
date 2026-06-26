{lib, lib', config, options, ...}:
let config' = config.dconf.gSettings';
    inherit (lib) mkOption pipe strings concatMap isOption const fix
                  genAttrs' forEach optionals mkMerge toCamelCase
                  updateManyAttrsByPath attrByPath mkOverride flip
                  mapAttrsToListRecursive mergeAttrsList splitString
                  isFunction optionalAttrs mapAttrsToListRecursiveCond
                  zipListsWith substring filter listToAttrs;
    inherit (lib.filesystem) listFilesRecursive;
    inherit (lib') pathComponents coerceToList attrEntry mkPipe neg
                   removeAttrsByPath importXML call;
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
    coerceToGVariant =
      let parse = input:
            let current = substring 0 1 input;
                remaining = substring 1 (-1) input;
                parser = parsers.${current};
            in parser current remaining;
          token = character: constructor:
            let parser = current: remaining: {
                  type = current;
                  inherit constructor remaining;
                };
            in attrEntry character parser;
          prefix = character: constructor:
            let parser = current: remaining:
                  let sub = parse remaining; in {
                    type = character + sub.type;
                    constructor = constructor sub.type;
                    inherit (sub) remaining;
                  };
            in attrEntry character parser;
          circumfix = characters: constructor:
            let character = substring 0 1 characters;
                terminator = substring 1 1 characters;
                parser = current: remaining:
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
                )) {};
            in attrEntry character parser;
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
      in type:
        if type == null
          then lib.hm.gvariant.mkValue
          else (parse type).constructor;
in {
  options.dconf.gSettings' = with lib.types; {
    packages = mkOption {
      description = "List of packages containing GSettings schemas.";
      type = listOf (either path package);
      default = [];
    };
    mappings = mkOption {
      description = ''
        Freeform configuration to translate to dconf settings.
      '';
      type = listOf (submodule {
        options = {
          schemaId = mkOption {
            description = "TODO";
            type = nullOr str;
            default = null;
          };
          path = mkOption {
            description = "TODO";
            type = str;
            apply = normalizeDConfPath;
          };
          configPath = mkOption {
            description = "TODO";
            type = listOf str;
          };
          priority = mkOption {
            description = "Priority of the generated config values.";
            type = int;
            default = 1200;
          };
        };
      });
      default = [];
    };
  };
  config.dconf.settings =
    let schemas = concatMap getGSettingsSchemas config'.packages;
        schemaById = pipe schemas [
          (flip genAttrs' (schema: attrEntry schema."@id" schema))
          (table: id: table.${id})
        ];
        schemasByPath = pipe schemas [
          (concatMap (schema: optionals (schema ? "@path") [{
            path = pathComponents schema."@path" ++ ["/"];
            update = const schema."@id";
          }]))
          (flip updateManyAttrsByPath {})
          (tree: path:
            let subtree = attrByPath (splitString "/" path) {} tree;
            in mapAttrsToListRecursive (const schemaById) subtree)
        ];
    in mkMerge (pipe config'.mappings [(concatMap (mapping:
      let schemas = if mapping.schemaId != null
            then [(schemaById mapping.schemaId // { "@path" = mapping.path; })]
            else schemasByPath mapping.path;
          suboptions = attrByPath mapping.configPath {} options;
          subconfig = pipe (suboptions.type.getSubOptions "") [
            (mapAttrsToListRecursiveCond (const (neg isOption)) (path: _: path))
            (removeAttrsByPath suboptions.value)
          ];
      in forEach schemas (schema:
        let path = normalizeDConfPath schema."@path";
            keys = coerceToList (schema.key or []);
            settings = mergeAttrsList (forEach keys (key:
              let name = key."@name";
                  type = key."@type" or null;
                  subconfigPath = pipe "${path}/${name}" [
                    (strings.removePrefix "${mapping.path}/")
                    pathComponents
                    (map toCamelCase)
                  ];
                  value = attrByPath subconfigPath (_: _) subconfig;
              in optionalAttrs (!(isFunction value)) {
                ${name} = pipe value [
                  (coerceToGVariant type)
                  (mkOverride mapping.priority)
                ];
              }));
        in optionalAttrs (settings != {}) {
          ${path} = settings;
        })
    ))]);
}
