{lib, lib', config, options, ...}:
let config' = config.dconf.gSettings';
    inherit (lib) mkOption pipe strings concatMap isOption const
                  genAttrs' forEach optionals mkMerge toCamelCase
                  updateManyAttrsByPath attrByPath mkOverride flip
                  mapAttrsToListRecursive mergeAttrsList splitString
                  isFunction optionalAttrs mapAttrsToListRecursiveCond;
    inherit (lib') coerceToGVariant getGSettingsSchemas pathComponents
                   coerceToList attrEntry normalizeDConfPath neg;
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
            (mapAttrsToListRecursiveCond (const (neg isOption)) (path: _: {
              inherit path;
              update = _: _;
            }))
            (flip updateManyAttrsByPath suboptions.value)
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
