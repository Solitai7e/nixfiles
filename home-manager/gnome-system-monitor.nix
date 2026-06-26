{lib, pkgs, config, ...}:
let inherit (lib) mkIf mkDefault mkOption mkMerge
                  mkEnableOption mkPackageOption;
    config' = config.programs.gnome-system-monitor';
in {
  options.programs.gnome-system-monitor' = with lib.types; mkOption {
    type = submodule {
      freeformType = attrsOf anything;
      options = {
        enable = mkEnableOption "gnome-system-monitor";
        package = mkPackageOption pkgs "gnome-system-monitor" {};
      };
    };
    default = {};
  };
  config = mkMerge [
    (mkIf config'.enable {
      home.packages = [config'.package];
      dconf.gSettings' = {
        mappings = [{
          path = "org/gnome/gnome-system-monitor";
          configPath = ["programs" "gnome-system-monitor'"];
        }];
        packages = [config'.package];
      };
    }) {
      programs.gnome-system-monitor' = {
        maximized = mkDefault true;
        currentTab = mkDefault "processes";
        cpuSmoothGraph = mkDefault false;
        resourcesDiskExpanded = mkDefault true;
        resourcesMemoryInIec = mkDefault true;
        resourcesNetExpanded = mkDefault true;
        networkTotalInBits = mkDefault false;
        processMemoryInIec = mkDefault true;
        showAllFs = mkDefault false;
        showDependencies = mkDefault false;
        showWhoseProcesses = mkDefault "all";
        disksview = {
          colDeviceWidth = mkDefault 322;
          colDirectoryWidth = mkDefault 655;
          colTypeWidth = mkDefault 84;
          sortCol = mkDefault "device";
          sortOrder = mkDefault 0;
        };
        proctree = {
          col0Visible = mkDefault true;
          col1Visible = mkDefault true; col1Width = mkDefault 133;
          col8Visible = mkDefault true; col8Width = mkDefault 66;
          col9Visible = mkDefault false;
          col10Visible = mkDefault false;
          col11Visible = mkDefault true; col11Width = mkDefault 48;
          col12Visible = mkDefault true; col12Width = mkDefault 69;
          col14Visible = mkDefault false;
          col15Visible = mkDefault true; col15Width = mkDefault 78;
          col22Visible = mkDefault true; col22Width = mkDefault 117;
          col23Visible = mkDefault true; col23Width = mkDefault 120;
          col24Visible = mkDefault true; col24Width = mkDefault 87;
          col25Visible = mkDefault true; col25Width = mkDefault 91;
          col26Visible = mkDefault false;
          sortCol = mkDefault 8;
          sortOrder = mkDefault 0;
          columnsOrder = [
            12 1 0 2 3 4 6 9 10 8 13 14 15 16
            17 18 19 20 21 24 25 22 23 11 26 7
          ];
        };
      };
    }];
}
