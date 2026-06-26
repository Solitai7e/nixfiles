{lib, pkgs, config, ...}:
let inherit (lib) mkIf elem catAttrs;
in mkIf (elem "xfce4-notifyd" (catAttrs "pname" config.home.packages)) {
  xdg.configFile."systemd/user/xfce4-notifyd.service.d/10-after-graphical.conf".text = ''
    [Unit]
    After=graphical-session.target
  '';
}
