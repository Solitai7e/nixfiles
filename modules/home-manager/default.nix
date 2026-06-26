{lib, pkgs, config, ...}:
let inherit (lib) mkDefault mkForce; in {
  home.homeDirectory = mkForce "/home/${config.home.username}";

  programs.home-manager.enable = mkDefault true;
  xdg.autostart.enable = mkDefault false;
}
