{lib, pkgs, config, ...}:
let inherit (lib) mkIf;
in mkIf config.dconf.enable {
  home.packages = [pkgs.dconf];
  home.activation = with lib.hm.dag; {
    deferDconfSettings = entryBetween ["dconfSettings"] ["reloadSystemd"] "";
  };
}
