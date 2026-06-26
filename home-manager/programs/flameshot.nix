{lib, pkgs, config, ...}:
let inherit (lib) mkOption mkDefault mkIf mkEnableOption mkPackageOption;
    inherit (pkgs) symlinkJoin;
    config' = config.programs.flameshot';
    settingsFormat = pkgs.formats.ini {};
in {
  options.programs.flameshot' = {
    enable = mkEnableOption "Flameshot";
    package = mkPackageOption pkgs "flameshot" {};
    settings = mkOption {
      description = "Settings for Flameshot";
      inherit (settingsFormat) type;
      default = {};
    };
  };
  config = mkIf config'.enable {
    home.packages = [(symlinkJoin {
      inherit (config'.package) pname version;
      paths = [config'.package];
      postBuild = ''
        rm -f "$out/share/applications/org.flameshot.Flameshot.desktop"
        sed '0,/^Exec=/{s/^Exec=.\+/Exec=flameshot gui/}' \
            "${config'.package}/share/applications/org.flameshot.Flameshot.desktop" \
            > "$out/share/applications/org.flameshot.Flameshot.desktop"
      '';
    })];
    xdg.configFile = mkIf (config'.settings != {}) {
      "flameshot/flameshot.ini".source =
        settingsFormat.generate "flameshot.ini" config'.settings;
    };
    programs.flameshot'.settings.General = {
      autoCloseIdleDaemon = mkDefault true;
      disabledTrayIcon = mkDefault true;
      showHelp = mkDefault false;
      showAbortNotification = mkDefault false;
      showStartupLaunchMessage = mkDefault false;
      savePath = mkDefault "${config.xdg.userDirs.pictures}/Screenshots";
    };
  };
}
