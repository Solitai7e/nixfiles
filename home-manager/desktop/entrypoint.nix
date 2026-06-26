{config, lib, pkgs, ...}:
let inherit (lib) mkIf mkDefault mkOption;
    inherit (pkgs) writeShellScriptBin;
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
    systemd.user.services.wayland-compositor = {
      Unit = {
        Description = "Wayland Compositor";
        BindsTo = ["graphical-session.target"];
        Before = ["graphical-session.target"];
        After = ["default.target"];
        X-SwitchMethod = mkDefault "keep-old";
      };
      Service = {
        ExecReload = mkDefault ["${pkgs.coreutils}/bin/true"];
        ExecStopPost = ["systemctl --user unset-environment WAYLAND_DISPLAY DISPLAY XAUTHORITY"];
        Slice = "session.slice";
      };
    };
    home.packages = [(writeShellScriptBin "start-graphical-session" ''
      set -eu -o pipefail
      mkdir -p "$XDG_RUNTIME_DIR/systemd/user/wayland-compositor.service.d"
      cat <<-EOF > "$XDG_RUNTIME_DIR/systemd/user/wayland-compositor.service.d/environment.conf"
      	[Service]
      	Environment=XDG_SESSION_ID=$XDG_SESSION_ID XDG_VTNR=$XDG_VTNR
      EOF
      systemctl --user daemon-reload
      exec systemctl --user start wayland-compositor.service
    '')];
    home.activation = with lib.hm.dag; {
      reloadWayland = entryAfter ["reloadSystemd"] ''
        run ${pkgs.systemd}/bin/systemctl --user $VERBOSE_ARG \
                                          try-reload-or-restart \
                                          wayland-compositor.service || :
      '';
    };
    programs.bash = mkIf config.desktop'.autostart {
      enable = true;
      profileExtra = ''
        if [[ $- == *i* ]] &&
           [[ $XDG_VTNR == 1 ]] &&
           [ "$(systemctl --user is-active graphical-session.target)" = "inactive" ]; then
          start-graphical-session
        fi
      '';
    };
  };
}
