{config, lib, pkgs, ...}:
let inherit (lib) mkIf mkDefault hashString toString forEach attrValues
                  escapeShellArg mkOption toJSON getExe optionalString;
    inherit (pkgs) writeShellScriptBin writeShellScript;
in {
  options.desktop' = with lib.types; {
    autostart = mkOption {
      description = ''
        Whether to automatically enter the
        graphical environment after logging in.
      '';
      type = bool;
      default = true;
    };
  };
  config = mkIf config.desktop'.enable {
    systemd.user.services.labwc = {
      Unit = {
        Description = "Lab Wayland Compositor";
        BindsTo = ["graphical-session.target"];
        Before = ["graphical-session.target"];
        After = ["default.target"];
        RefuseManualStart = true;
        X-SwitchMethod = "reload";
        X-Restart-Triggers = [(hashString "sha256" (toJSON config.wayland.windowManager.labwc))];
      };
      Service = {
        Type = "notify";
        ExecStart = getExe config.wayland.windowManager.labwc.package;
        ExecReload = ["${getExe config.wayland.windowManager.labwc.package} -r"];
        ExecStopPost = ["systemctl --user unset-environment WAYLAND_DISPLAY DISPLAY XAUTHORITY"];
        NotifyAccess = "all";
        Slice = "session.slice";
      };
    };
    home.packages = [(writeShellScriptBin "start-graphical-session" ''
      if systemctl --user is-active labwc.service; then
        echo "Graphical session already started." >&2
        exit 1
      fi
      systemctl --user edit --runtime --stdin labwc.service <<-EOF
      	[Unit]
      	RefuseManualStart=no

      	[Service]
      	Environment=XDG_SESSION_ID=$XDG_SESSION_ID
      	Environment=XDG_VTNR=$XDG_VTNR
      	ExecStopPost=systemctl --user revert --runtime labwc.service
      EOF
      systemctl --user start labwc.service
    '')];
    wayland.windowManager.labwc = {
      enable = mkDefault true;
      rc = {
        desktops."@number" = mkDefault "4";
        theme.name = mkDefault config.gtk.theme.name;
        theme.icon = mkDefault config.gtk.iconTheme.name;
        theme.dropShadows = mkDefault "yes";
        windowSwitcher = {
          "@preview" = mkDefault "no";
          "@outlines" = mkDefault "yes";
          osd."@style" = mkDefault "thumbnail";
        };
        snapping.range = {
          inner = mkDefault "50";
          outer = mkDefault "50";
        };
        keyboard.keybind =
          forEach (attrValues config.desktop'.keybindings) (keybinding: {
            "@key" = with keybinding.hotkey;
              optionalString ctrl "C-" +
              optionalString meta "A-" +
              optionalString shift "S-" +
              optionalString super "W-" +
              optionalString hyper "H-" +
              key;
            "@onRelease" = if keybinding.triggerOn == "release" then "yes" else "no";
            action = {
              "@name" = "Execute";
              "@command" = writeShellScript "keybinding" keybinding.execute;
            };
          }) ++ [
            { "@key" = "W-Tab"; action."@name" = "NextWindow"; }
            { "@key" = "W-f";   action."@name" = "ToggleAlwaysOnTop"; }
            { "@key" = "W-d";   action."@name" = "ToggleOmnipresent"; }
            { "@key" = "A-F4";  action."@name" = "Close"; }
          ];
      };
      environment = [
        "XCURSOR_SIZE=${escapeShellArg (toString config.gtk.cursorTheme.size)}"
        "XCURSOR_THEME=${escapeShellArg config.gtk.cursorTheme.name}"
      ];
      systemd.enable = false;
      autostart = ["${pkgs.systemd}/bin/systemd-notify --ready"];
    };
    xdg.configFile."labwc/shutdown".text = ''
      ${pkgs.systemd}/bin/systemd-notify --stopping
      ${pkgs.systemd}/bin/systemctl --user stop graphical-session.target
    '';
    dconf.settings."org/gnome/desktop/wm/preferences" = {
      button-layout = mkDefault "appmenu:minimize,maximize,close";
    };
    programs.bash = mkIf config.desktop'.autostart {
      enable = mkDefault true;
      profileExtra = ''
        if [[ $- == *i* ]] && [[ -v XDG_SESSION_ID ]] && [[ $XDG_VTNR == 1 ]]; then
          start-graphical-session
        fi
      '';
    };
  };
}
