{lib, pkgs, config, ...}:
let inherit (lib) mkIf mkOverride;
in mkIf config.desktop'.profile.frankenstein.enable {
  gtk.theme.package = mkOverride 900 pkgs.materia-theme;
  gtk.theme.name = mkOverride 900 "Materia-dark-compact";
  gtk.iconTheme.package = mkOverride 900 pkgs.papirus-icon-theme;
  gtk.iconTheme.name = mkOverride 900 "Papirus-Dark";
}
