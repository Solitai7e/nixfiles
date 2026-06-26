{lib, pkgs, config, ...}:
let inherit (lib) mkIf hm;
in mkIf config.dconf.enable {
  home.packages = [pkgs.dconf];
  home.activation = with hm.dag; {
    deferDconfSettings = entryBetween ["dconfSettings"] ["reloadSystemd"] "";
  };
}
