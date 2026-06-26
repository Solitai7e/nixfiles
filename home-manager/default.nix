{lib, systemConfig, config, ...}:
let inherit (lib) mkDefault mkForce; in {
  home.homeDirectory =
    mkForce systemConfig.users.users.${config.home.username}.home;

  programs.home-manager.enable = mkDefault true;
  xdg.autostart.enable = mkDefault false;

  systemd.user = { inherit (config.home) sessionVariables; };
}
