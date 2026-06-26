{config, lib, lib', pkgs, ...}:
let inherit (lib) mkIf mkDefault mkOption getExe flip range toString pipe;
    inherit (lib') getAttrs' escapeShellVars';
    config' = config.desktop';
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
  config = mkIf config'.enable {
    programs.bash = {
      enable = true;
      profileExtra = ''
        if [[ $- == *i* ]] && [[ -v XDG_SESSION_ID ]] && [[ -v XDG_VTNR ]]; then
          start-graphical-session() {
            local labwc=${getExe config.wayland.windowManager.labwc.package}
            systemd-run --user --unit=wayland-compositor.service --collect \
                         --description="Wayland Compositor" \
                         --service-type=notify \
                         -p BindsTo=graphical-session.target \
                         -p Before=graphical-session.target \
                         -p After=default.target \
                         -p NotifyAccess=all \
                         -E XDG_SESSION_ID \
                         -E XDG_VTNR \
                         -p ExecReload="$labwc -r" \
                         -p ExecStopPost="systemctl --user unset-environment WAYLAND_DISPLAY DISPLAY XAUTHORITY" \
                         --slice=session.slice \
              "$labwc" "$@"
          }
          if ((${toString config'.autostart})) &&
             [[ $XDG_VTNR == 1 ]] &&
             [ "$(systemctl --user is-active graphical-session.target)" = "inactive" ]; then
            start-graphical-session
          fi
        fi
      '';
    };
    wayland.windowManager.labwc = {
      enable = true;
      rc = {
        desktops.names.name = mkDefault (map (i: "   ${toString i}   ") (range 1 4));
        theme.name = mkDefault config.gtk.theme.name;
        theme.icon = mkDefault config.gtk.iconTheme.name;
        theme.dropShadows = mkDefault "yes";
        windowSwitcher = {
          "@preview" = mkDefault "no";
          "@outlines" = mkDefault "yes";
          osd."@style" = mkDefault "thumbnail";
        };
      };
      environment = pipe ["XCURSOR_PATH" "XCURSOR_THEME" "XCURSOR_SIZE"] [
        (flip getAttrs' config.systemd.user.sessionVariables)
        escapeShellVars'
      ];
      systemd.enable = false;
      autostart = ["${pkgs.systemd}/bin/systemd-notify --ready"];
    };
    xdg.configFile."labwc/shutdown".text = ''
      ${pkgs.systemd}/bin/systemd-notify --stopping
      ${pkgs.systemd}/bin/systemctl --user stop graphical-session.target
    '';
    home.activation = with lib.hm.dag; {
      reloadWayland = entryAfter ["reloadSystemd"] ''
        run ${pkgs.systemd}/bin/systemctl \
            --user $VERBOSE_ARG reload wayland-compositor.service || :
      '';
    };
  };
}
