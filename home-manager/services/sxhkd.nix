{config, lib, pkgs, ...}:
let inherit (lib) mkIf mkOption mkEnableOption mkPackageOption
                  splitString escapeShellArgs optionalString pipe
                  strings concatMapStrings mapAttrsToList;
    config' = config.services.sxhkd';
    splitLines = string:
      splitString "\n" (strings.removeSuffix "\n" string);
    mkKeybinding = hotkey: commands:
      let commands' = optionalString (commands != null) (
            map (line: "\t${line}") (splitLines commands));
      in strings.join "\n" (["${hotkey}"] ++ commands');
in {
  options.services.sxhkd' = with lib.types; {
    enable = mkEnableOption "simple X hotkey daemon";
    package = mkPackageOption pkgs "sxhkd" {};
    keybindings = mkOption {
      type = attrsWith {
        placeholder = "hotkey";
        elemType = nullOr str;
      };
      default = {};
    };
    extraOptions = mkOption {
      type = listOf str;
      default = [];
    };
  };
  config = mkIf config'.enable {
    xdg.configFile."sxhkd/sxhkdrc".text = pipe config'.keybindings [
      (mapAttrsToList mkKeybinding)
      (strings.join "\n\n")
    ];
    systemd.user.services.sxhkd = {
      Unit.After = ["graphical-session.target"];
      Unit.PartOf = ["graphical-session.target"];
      Install.WantedBy = ["graphical-session.target"];
      Service = {
        Type = "exec";
        ExecStart = escapeShellArgs (
          ["${config'.package}/bin/sxhkd"] ++ config'.extraOptions);
        Slice = "session.slice";
        OOMPolicy = "continue";
      };
      Unit.X-SwitchMethod = "restart";
    };
  };
}
