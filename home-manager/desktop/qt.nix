{lib, config, ...}:
let inherit (lib) mkIf mkDefault; in {
  qt.enable = mkDefault (config.desktop'.profileName != null);
  qt.style.name = mkIf config.gtk.gtk2.enable (mkDefault "gtk2");
  qt.platformTheme.name = mkIf (config.qt.style.name == "gtk2") (mkDefault "gtk2");
}
