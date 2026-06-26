{lib, pkgs, config, ...}:
let inherit (lib) mkIf mkOverride hm;
in mkIf config.xfconf.enable {
  home.packages = [pkgs.xfconf];
  home.activation.xfconfSettings =
    hm.dag.entryAfter ["reloadSystemd"] (mkOverride 10000 "");
}
