{lib, pkgs, config, ...}:
let inherit (lib) mkIf mkDefault;
in mkIf config.desktop'.profile.frankenstein.enable {
  gtk.theme.package = mkDefault pkgs.yaru-theme;
  gtk.theme.name = mkDefault "Yaru-blue-dark";
}
