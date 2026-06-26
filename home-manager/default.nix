{lib, systemConfig, config, ...}:
let inherit (lib) mkDefault; in {
  home.homeDirectory =
    systemConfig.users.users.${config.home.username}.home;

  xdg.autostart.enable = mkDefault false;

  systemd.user = { inherit (config.home) sessionVariables; };
}
