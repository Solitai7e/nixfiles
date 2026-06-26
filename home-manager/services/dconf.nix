{lib, pkgs, systemConfig, config, ...}:
let inherit (lib) mkIf mkOverride hm;
in mkIf config.dconf.enable {
  home.packages = [pkgs.dconf];
  home.activation.dconfSettings =
    hm.dag.entryAfter ["reloadSystemd"] (mkOverride 10000 "");
}
