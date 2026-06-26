{config, lib, pkgs, utils, ...}:
let inherit (lib) mkOption mkIf mkPackageOption toString
                  genAttrs getExe optionals optionalString
                  concatLists mapAttrsToList;
    inherit (utils) escapeSystemdExecArgs;
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
    package = mkPackageOption pkgs "xwallpaper" {};
  };
  config =
    let trimToArgs = {width, height, x, y}:
          optionals (width != null && height != null) ["--trim" (
            "${toString width}x${toString height}" +
            optionalString (x != null) "+${toString x}" +
            optionalString (y != null) "+${toString y}"
          )];
        settingsToArgs = output: {file, method, trim, ...}:
          ["--output" output "--${method}" "${file}"] ++ trimToArgs trim;
        cmdline =
          [(getExe config'.package) "--debug"] ++
          optionals config'.daemon ["--daemon"] ++
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
          ExecStart = escapeSystemdExecArgs cmdline;
          Slice = "session.slice";
        };
      };
    };
}
