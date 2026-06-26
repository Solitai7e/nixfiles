{lib, pkgs, config, ...}:
let inherit (lib) mkOption mkDefault mkIf mkEnableOption mkPackageOption;
    inherit (config.lib.file) mkOutOfStoreSymlink;
    config' = config.programs.gimp';
in {
  options.programs.gimp' = {
    enable = mkEnableOption "the GNU Image Manipulation Program";
    package = mkPackageOption pkgs "gimp" {};
    #settings = mkOption {
    #  description = "Settings for GIMP";
    #  inherit (settingsFormat) type;
    #  default = {};
    #};
  };
  config = mkIf config'.enable {
    home.packages = [config'.package];
    xdg.configFile."GIMP".source =
      mkOutOfStoreSymlink "${config.home.stateDirectory'}/gimp";
    systemd.user.tmpfiles.rules =
      ["d ${config.home.stateDirectory'}/gimp"];
  };
}
