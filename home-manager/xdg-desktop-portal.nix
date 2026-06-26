{lib, config, pkgs, ...}:
let config' = config.xdg.portal;
    inherit (lib) mkDefault mkIf;
in mkIf config'.enable {
  xdg.portal = {
    config.preferred.default = mkDefault "gtk";
    extraPortals = mkIf (config'.config.preferred.default == "gtk")
      [pkgs.xdg-desktop-portal-gtk];
    xdgOpenUsePortal = mkDefault true;
  };
}
