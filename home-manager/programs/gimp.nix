{lib, pkgs, config, ...}:
let config' = config.programs.gimp';
    inherit (lib) mkIf mkEnableOption mkPackageOption;
    inherit (config.lib.file) mkOutOfStoreSymlink;
in {
  options.programs.gimp' = {
    enable = mkEnableOption "the GNU Image Manipulation Program";
    package = mkPackageOption pkgs "gimp" {};
  };
  config = mkIf config'.enable {
    home.packages = [config'.package];
    xdg.configFile."GIMP".source =
      mkOutOfStoreSymlink "${config.home.dataDirectory'}/state/gimp";
    systemd.user.tmpfiles.rules =
      ["d ${config.home.dataDirectory'}/state/gimp"];
  };
}
