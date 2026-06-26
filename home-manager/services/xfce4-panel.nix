#{lib, pkgs, config, ...}:
#let inherit (lib) mkOption mkEnableOption mkPackageOption
#                  mkIf mkDefault groupBy getAttr imap pipe
#                  mapAttrsToList forEach;
#    config' = config.services.xfce4-panel;
#    wtf = items: pipe items [
#      (imap (i: item: item // { position = i; }))
#      (groupBy (getAttr "id"))
#      (mapAttrsToList (id: items: {}))
#    ];
#    taggedListOf = tagFunc: lib.types.listOf // {
#      name = "taggedListOf";
#      merge = {loc, defs}: lib.types.listOf.merge {
#        inherit loc;
#        defs = forEach defs (def@{value, ...}: pipe value [
#          (imap (i: item: item // { position = i; }))
#          (groupBy tagFunc)
#          (mapAttrsToList (tag: items: {}))
#        ]);
#      };
#    };
#    plugin = with lib.types; submodule {
#      options = {
#        id = mkOption {
#          type = nullOr str;
#          default = null;
#        };
#        type = mkOption {
#          type = str;
#        };
#        settings = mkOption {
#          type = submodule { freeformType = attrsOf str; };
#          default = {};
#        };
#      };
#    };
#    panel = with lib.types; submodule {
#      options = {
#        id = mkOption {
#          type = nullOr str;
#          default = null;
#        };
#        plugins = mkOption {
#          type = listOf plugin;
#          default = [];
#        };
#        settings = mkOption {
#          type = submodule { freeformType = attrsOf str; };
#          default = {};
#        };
#      };
#    };
#in {
#  options.services.xfce4-panel' = with lib.types; {
#    enable = mkEnableOption "xfce4-panel";
#    panels = mkOption {
#      type = listOf panel;
#      default = [];
#    };
#    package = mkPackageOption "xfce4-panel" {};
#  };
#  config = mkIf config'.enable {
#    xfconf.enable = mkDefault true;
#    xfconf.settings = {
#
#    };
#  };
#}
{}
