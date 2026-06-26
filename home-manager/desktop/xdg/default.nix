{config, lib, ...}:
let inherit (lib) mkDefault mkIf;
in mkIf config.desktop'.enable {
  xdg.autostart.enable = mkDefault false;
  xdg.mimeApps.enable = mkDefault true;
}
