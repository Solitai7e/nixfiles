{lib, pkgs, config, ...}:
let inherit (lib) mkIf mkEnableOption escapeShellArg;
    inherit (pkgs) writeShellApplication;
    xorg-server' = pkgs.xorg-server.overrideAttrs (final: prev: {
      buildInputs = prev.buildInputs or [] ++ [pkgs.xf86-input-libinput];
      postInstall = prev.postInstall or "" + ''
        cp -vTR ${escapeShellArg "${pkgs.xf86-input-libinput}"} "$out"
      '';
    });
in {
  options = {
    programs.xserver'.enable = mkEnableOption "X Server";
  };
  config = mkIf config.programs.xserver'.enable {
    home.packages = [xorg-server' (writeShellApplication {
      name = "startx";
      runtimeInputs = with pkgs; [xorg-server' xauth systemd coreutils util-linux];
      text = ''
        systemd-run --user --quiet --wait \
                    --service-type=oneshot \
                    --collect \
                    -p Wants=home-activation.service \
                    -p After=home-activation.service \
          true

        exit_traps=""
        exit_trap() { exit_traps="$*; $exit_traps"; }
        trap 'trap "" EXIT; eval "$exit_traps"' EXIT HUP INT TERM

        DISPLAY=":$(id -u)" XAUTHORITY="$XDG_RUNTIME_DIR/Xauthority.$$"
        systemctl --user set-environment DISPLAY="$DISPLAY" XAUTHORITY="$XAUTHORITY"
        exit_trap systemctl --user unset-environment DISPLAY XAUTHORITY

        xauth -q -f "$XAUTHORITY" add "$DISPLAY" . "$(mcookie)"
        exit_trap 'rm -f "$XAUTHORITY"'

        Xorg "$DISPLAY" "vt$XDG_VTNR" -auth "$XAUTHORITY" \
                                      -nolisten tcp \
                                      -noreset \
                                      -keeptty \
                                      "$@" &
        exit_trap kill $!

        systemd-run --user --unit xserver.service \
                    --service-type=oneshot \
                    --remain-after-exit \
                    --collect \
                    -p BindsTo=graphical-session.target \
                    -p Before=graphical-session.target \
                    -p Slice=session.slice \
                    -p ExecStopPost=-"$(type -P kill) -TERM $$" \
          true
        exit_trap 'systemctl --user --quiet stop xserver.service 2> /dev/null || :'

        wait
      '';
      checkPhase = "";
    })];
  };
}
