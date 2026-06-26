{lib, config, pkgs, ...}:
let config' = config.xdg.portal;
    inherit (lib) mkDefault mkIf;
in mkIf config.desktop'.enable {
  xdg.portal = {
    enable = mkDefault true;
    config.preferred.default = mkDefault "gtk";
    extraPortals = mkIf (config'.config.preferred.default == "gtk")
      [pkgs.xdg-desktop-portal-gtk];
    xdgOpenUsePortal = mkDefault true;
  };
}
