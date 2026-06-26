{lib, config, ...}:
let inherit (lib) mkIf mkDefault; in {
  options.desktop'.panel = {

  };
  config = mkIf config.desktop'.enable {
    programs.quickshell = {
      enable = mkDefault true;
      systemd.enable = mkDefault true;
    };
    xdg.configFile."quickshell" = mkDefault { source = ./.; };
  };
}
