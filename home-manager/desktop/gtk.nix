{lib, lib', pkgs, config, ...}:
let inherit (lib) mkIf mkDefault mkForce toString;
    inherit (lib') mkFileUri;
in mkIf config.desktop'.enable rec {
  gtk.enable = mkDefault config.desktop'.enable;

  gtk.font.name = mkDefault "Sans Serif";
  gtk.font.size = mkDefault 10;

  gtk.colorScheme = mkDefault "dark";

  gtk.iconTheme.package = mkDefault config.gtk.theme.package;
  gtk.iconTheme.name = mkDefault config.gtk.theme.name;

  gtk.cursorTheme.package = mkDefault pkgs.adwaita-icon-theme;
  gtk.cursorTheme.name = mkDefault "Adwaita";
  gtk.cursorTheme.size = mkDefault 24;

  gtk.gtk2.extraConfig = ''
    gtk-menu-images = 1
    gtk-button-images = 1
  '';
  gtk.gtk3.extraConfig = {
    gtk-menu-images = true;
    gtk-button-images = true;
    gtk-dialogs-use-header = true;
  };
  gtk.gtk4.extraConfig = {
    gtk-dialogs-use-header = true;
  };
  dconf.settings."org/gnome/desktop/wm/preferences" = {
    button-layout = mkDefault "appmenu:minimize,maximize,close";
  };

  gtk.gtk4.theme = mkDefault config.gtk.theme;
  xdg.configFile."gtk-4.0/gtk.css".text =
    mkIf config.gtk.gtk4.enable (mkForce config.gtk.gtk4.extraCss);

  home.sessionVariables = {
    XCURSOR_SIZE = mkDefault (toString config.gtk.cursorTheme.size);
    XCURSOR_THEME = mkDefault config.gtk.cursorTheme.name;
    ADW_DISABLE_PORTAL = mkIf (!config.xdg.portal.enable) (mkDefault "1");
  };
  systemd.user = { inherit (home) sessionVariables; };

  gtk.gtk3.bookmarks =
    let configDir = config.home.configDirectory';
        xdgUserDirs = map (name: config.xdg.userDirs.${name}) [
          "projects" "documents" "music"
          "pictures" "videos" "download"
        ];
    in [("${mkFileUri configDir} Configuration")] ++
       map mkFileUri xdgUserDirs;
}
