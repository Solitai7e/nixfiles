{config, lib, pkgs, ...}:
let inherit (lib) match mkIf mkOverride toSentenceCase optionalString;
    package = pkgs.yaru-theme.overrideAttrs (final: prev: {
      patches = (prev.patches or []) ++ [./metacity.patch];
    });
in mkIf (config.desktop'.enable &&
         match "yaru-[a-z0-9]+" config.desktop'.theme != null) rec {
  gtk.theme.package = mkOverride 900 package;
  gtk.theme.name = mkOverride 900 (
    toSentenceCase config.desktop'.theme +
    optionalString (config.gtk.colorScheme == "dark") "-dark");
  gtk.iconTheme = { inherit (gtk.theme) package name; };
}
