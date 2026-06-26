{lib, pkgs, config, ...}:
let inherit (lib) mkIf;
in mkIf config.xfconf.enable {
  home.packages = [pkgs.xfconf];
  home.activation = with lib.hm.dag; {
    deferXfconfSettings = entryBetween ["xfconfSettings"] ["reloadSystemd"] "";
  };
}
