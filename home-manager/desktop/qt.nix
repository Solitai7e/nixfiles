{lib, config, ...}:
let inherit (lib) mkIf mkDefault;
in mkIf config.desktop'.enable {
  qt = {
    enable = mkDefault true;
    style.name =
      mkIf config.gtk.gtk2.enable (mkDefault "gtk2");
    platformTheme.name =
      mkIf (config.qt.style.name == "gtk2") (mkDefault "gtk2");
  };
}
