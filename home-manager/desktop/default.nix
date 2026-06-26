{lib, systemConfig, config, ...}:
let inherit (lib) mkIf mkEnableOption mkDefault;
    config' = config.desktop';
in {
  options.desktop'.enable = mkEnableOption "the graphical environment";
  config = mkIf config'.enable {
    programs.nemo'.enable = mkDefault true;
    programs.gnome-terminal.enable = mkDefault true;
    programs.cudatext.enable = mkDefault true;
    programs.gnome-system-monitor'.enable = mkDefault true;
    programs.chromium = {
      enable = mkDefault true;
      defaultBrowser' = mkDefault true;
    };
    programs.gthumb'.enable = mkDefault true;
    programs.flameshot'.enable = mkDefault true;
    services.network-manager-applet.enable =
      mkDefault systemConfig.networking.networkmanager.enable;

    services.polkit-gnome.enable = mkDefault true;
    services.gvfs'.enable = mkDefault true;
  };
}
