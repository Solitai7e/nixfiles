{lib, pkgs, config, ...}:
let inherit (lib) mkIf mkDefault mkEnableOption mkForce; in {
  options.desktop'.profile.frankenstein = {
    enable = mkEnableOption ''the desktop configuration "Frankenstein"'';
  };
  config = mkIf config.desktop'.profile.frankenstein.enable {
    programs.cudatext.enable = mkDefault true;
    programs.gnome-terminal.enable = mkDefault true;
    services.polkit-gnome.enable = mkDefault true;

    services.xwallpaper' = {
      enable = true;
      settings = mkDefault { all.file = ./wallpaper.jpg; };
    };
  };
}
