{lib, pkgs, config, ...}:
let inherit (lib) mkIf hm;
in mkIf config.xfconf.enable {
  home.packages = [pkgs.xfconf];
  home.activation = with hm.dag; {
    deferXfconfSettings = entryBetween ["xfconfSettings"] ["reloadSystemd"] "";
  };
}
