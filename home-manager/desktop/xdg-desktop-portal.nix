{lib, pkgs, ...}:
let inherit (lib) mkDefault mkIf; in {
  xdg.portal = {
    enable = mkDefault true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
    config.preferred.default = mkDefault "gtk";
    xdgOpenUsePortal = mkDefault true;
  };
}
