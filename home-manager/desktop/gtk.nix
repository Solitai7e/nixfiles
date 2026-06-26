{lib, lib', pkgs, config, ...}:
let inherit (lib) mkIf mkDefault mkForce mkBefore;
    inherit (lib') mkFileUri;
in mkIf config.desktop'.enable {
  gtk.enable = mkDefault true;
  gtk.font = {
    name = mkDefault "Sans Serif";
    size = mkDefault 10;
  };
  gtk.iconTheme = {
    package = mkDefault config.gtk.theme.package;
    name = mkDefault config.gtk.theme.name;
  };
  gtk.cursorTheme = {
    package = mkDefault pkgs.adwaita-icon-theme;
    name = mkDefault "Adwaita";
    size = mkDefault 24;
  };

  gtk.colorScheme = mkDefault "dark";
  gtk.gtk2.extraConfig = mkBefore ''
    gtk-menu-images = 1
    gtk-button-images = 1
  '';
  gtk.gtk3.extraConfig = {
    gtk-menu-images = mkDefault true;
    gtk-button-images = mkDefault true;
    gtk-dialogs-use-header = mkDefault true;
  };
  gtk.gtk4.extraConfig = {
    gtk-dialogs-use-header = mkDefault true;
  };

  gtk.gtk4.theme = mkDefault config.gtk.theme;
  xdg.configFile."gtk-4.0/gtk.css" = mkIf config.gtk.gtk4.enable
    (mkForce { text = config.gtk.gtk4.extraCss; });

  gtk.gtk3.bookmarks =
    [("${mkFileUri "${config.home.dataDirectory'}/config"} Configuration")] ++
    map mkFileUri (map (name: config.xdg.userDirs.${name}) [
      "projects" "documents" "music"
      "pictures" "videos" "download"
    ]);

  home.sessionVariables.ADW_DISABLE_PORTAL =
    mkIf (!config.xdg.portal.enable) (mkDefault "1");
  systemd.user.sessionVariables.ADW_DISABLE_PORTAL =
    mkIf (!config.xdg.portal.enable) (mkDefault "1");
}
