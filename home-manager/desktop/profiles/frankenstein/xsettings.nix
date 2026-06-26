{lib, config, ...}:
let inherit (lib) mkIf mkDefault; in
mkIf config.desktop'.profile.frankenstein.enable {
  services.xsettingsd = {
    enable = mkDefault true;
    settings = {
      "Net/ThemeName" = mkDefault config.gtk.theme.name;
      "Net/IconThemeName" = mkDefault config.gtk.iconTheme.name;
      "Gtk/MenuImages" = mkDefault true;
      "Gtk/ButtonImages" = mkDefault true;
      "Gtk/DialogsUseHeader" = mkDefault true;
      "Gtk/ToolbarStyle" = mkDefault "GTK_TOOLBAR_BOTH_HORIZ";
      "Gtk/EnablePrimaryPaste" = mkDefault false;
      "Gtk/RecentFilesEnabled" = mkDefault false;
      "Net/EnableEventSounds" =  mkDefault false;
    };
  };
}
