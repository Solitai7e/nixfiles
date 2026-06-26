{lib, pkgs, systemConfig, config, ...}:
let inherit (lib) mkIf mkDefault mkEnableOption; in {
  options.desktop'.profile.frankenstein = {
    enable = mkEnableOption ''the desktop configuration "Frankenstein"'';
  };
  config = mkIf config.desktop'.profile.frankenstein.enable {
    programs.cudatext.enable = mkDefault true;
    programs.gnome-terminal.enable = mkDefault true;
    programs.flameshot'.enable = mkDefault true;

    services.polkit-gnome.enable = mkDefault true;

    services.xwallpaper' = {
      enable = true;
      settings = mkDefault { all.file = ./wallpaper.jpg; };
    };
    services.network-manager-applet.enable =
      mkDefault systemConfig.networking.networkmanager.enable;
  };
}
