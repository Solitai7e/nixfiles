{lib, pkgs, config, ...}:
let inherit (lib) mkIf mkDefault;
in mkIf config.desktop'.enable {
  qt = rec {
    enable = mkDefault true;
    platformTheme.name = mkDefault "qtct";
    qt5ctSettings = {
      Appearance = {
        style = mkIf config.qt.kvantum.enable (mkDefault "kvantum");
        icon_theme = mkDefault config.gtk.iconTheme.name;
        standard_dialogs = mkDefault "xdgdesktopportal";
      };
      Fonts = {
        general = mkDefault ''"Sans Serif,10"'';
        fixed = mkDefault ''"Monospace,10"'';
      };
    };
    qt6ctSettings = qt5ctSettings;
    kvantum.enable = mkDefault true;
    style.package = with pkgs; mkIf config.qt.kvantum.enable [
      libsForQt5.qtstyleplugin-kvantum
      qt6Packages.qtstyleplugin-kvantum
      kdePackages.qqc2-desktop-style
      kdePackages.kirigami
    ];
  };
}
