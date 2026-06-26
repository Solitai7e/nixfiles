{lib, config, ...}:
let config' = config.desktop'.panel;
    inherit (lib) mkIf mkDefault mkOption;
in {
  options.desktop'.panel = with lib.types; {
    enable = mkOption {
      description = "Whether to enable the desktop panel.";
      type = bool;
      default = config.desktop'.enable;
    };
    height = mkOption {
      description = "Height of the panel.";
      type = int;
      default = 30;
    };
    position = mkOption {
      description = "Where to position the panel.";
      type = enum ["top" "bottom"];
      default = "bottom";
    };
    widgets = mkOption {
      type = listOf (submodule {
        freeformType = attrsOf anything;
        options = {
          id = mkOption {
            description = "A unique identifier for the widget.";
            type = nullOr str;
            default = null;
          };
          class = mkOption {
            description = "Type of the widget.";
            type = str;
          };
        };
      });
      default = [];
    };
  };
  config = mkIf config'.enable {
    programs.quickshell = {
      enable = mkDefault true;
      systemd.enable = mkDefault true;
    };
    xdg.configFile."quickshell" = mkDefault { source = ./.; };
  };
}
