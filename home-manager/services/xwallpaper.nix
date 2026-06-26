{config, lib, pkgs, ...}:
let inherit (lib) mkOption mkIf genAttrs mapAttrs optional
                  optionalString toString escapeShellArgs
                  optionals concatLists mapAttrsToList;
    config' = config.services.xwallpaper';
in {
  options.services.xwallpaper' = with lib.types; {
    enable = mkOption {
      description = "Whether to enable xwallpaper.";
      type = bool;
      default = false;
    };
    settings = mkOption {
      description = ''
        Per-output xwallpaper settings.
        The special value "all" can be used to
        apply the settings to every output.
      '';
      type = attrsWith {
        placeholder = "output";
        elemType = submodule ({name, ...}: {
          options = {
            file = mkOption {
              description = "Path to the wallpaper image.";
              type = path;
            };
            method = mkOption {
              description = "How the image should be displayed.";
              type = enum [
                "center" "focus" "maximize"
                "stretch" "tile" "zoom"
              ];
              default = "zoom";
            };
            trim = genAttrs ["width" "height" "x" "y"] (attribute: mkOption {
              description = ''
                Area of interest in the image.
                At least width and height must be specified.
              '';
              type = nullOr int;
              default = null;
            });
          };
        });
      };
    };
    daemon = mkOption {
      description = "Whether to run xwallpaper in daemon mode.";
      type = bool;
      default = false;
    };
    package = mkOption {
      description = "The xwallpaper package to use.";
      type = package;
      default = pkgs.xwallpaper;
    };
  };
  config =
    let settingsToArgs = output: {file, method, trim, ...}:
          ["--output" output "--${method}" "${file}"] ++
          optionals (trim.width != null && trim.height != null) ["--trim" (
            "${toString trim.width}x${toString trim.height}" +
            optionalString (trim.x != null) "+${toString trim.x}" +
            optionalString (trim.y != null) "+${toString trim.y}"
          )];
        args = optionals config'.daemon ["--daemon" "--debug"] ++
               concatLists (mapAttrsToList settingsToArgs config'.settings);
    in mkIf config'.enable {
      systemd.user.services.xwallpaper = {
        Unit.After = ["graphical-session.target"];
        Unit.PartOf = ["graphical-session.target"];
        Install.WantedBy = ["graphical-session.target"];
        Service = {
          Type = if config'.daemon then "forking" else "oneshot";
          RemainAfterExit = mkIf (!config'.daemon) "yes";
          GuessMainPID = mkIf config'.daemon "yes";
          ExecStart = "${config'.package}/bin/xwallpaper ${escapeShellArgs args}";
          Slice = "session.slice";
        };
      };
    };
}
