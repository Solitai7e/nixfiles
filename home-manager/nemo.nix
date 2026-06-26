{config, lib, pkgs, ...}:
let inherit (lib) mkDefault mkPackageOption
                  mkIf mkOption mkEnableOption;
    config' = config.programs.nemo';
in {
  options.programs.nemo' = with lib.types; mkOption {
    type = submodule {
      freeformType = attrsOf anything;
      options = {
        enable = mkEnableOption "Nemo file manager";
        package = mkPackageOption pkgs "nemo" {};
        desktop.enable' = mkEnableOption "Nemo desktop service";
      };
    };
    default = {};
  };
  config = mkIf config'.enable {
    home.packages = [config'.package];
    dconf.gSettings' = {
      mappings = [{
        path = "org/nemo";
        configPath = ["programs" "nemo'"];
      }];
      packages = [config'.package];
    };
    systemd.user.services.nemo-desktop = mkIf config'.desktop.enable' {
      Unit.After = ["graphical-session.target"];
      Unit.PartOf = ["graphical-session.target"];
      Install.WantedBy = ["graphical-session.target"];
      Service = {
        Type = "exec";
        ExecStart = "${config'.package}/bin/nemo-desktop";
        Slice = "session.slice";
      };
    };
  };
  imports = [{
    programs.nemo' = {
      listView.enableFolderExpansion = mkDefault true;
      iconView.defaultZoomLevel = mkDefault "small";
      compactView = {
        allColumnsHaveSameWidth = mkDefault true;
        defaultZoomLevel = mkDefault "small";
      };
      preferences = {
        closeDeviceViewOnDeviceEject = mkDefault false;
        dateFontChoice = mkDefault "no-mono";
        dateFormat = mkDefault "iso";
        defaultFolderViewer = mkDefault "list-view";
        defaultSortOrder = mkDefault "type";
        detectContent = mkDefault false;
        enableDelete = mkDefault false;
        inheritFolderViewer = mkDefault true;
        quickRenamesWithPauseInBetween = mkDefault false;
        showHiddenFiles = mkDefault true;
        showLocationEntry = mkDefault true;
        sizePrefixes = mkDefault "base-2";
        thumbnailLimit = mkDefault 10485760;
        menuConfig = {
          backgroundMenuOpenAsRoot = mkDefault false;
          backgroundMenuOpenInTerminal = mkDefault true;
          selectionMenuFavorite = mkDefault false;
          selectionMenuOpenAsRoot = mkDefault false;
          selectionMenuPin = mkDefault false;
        };
      };
      search = {
        searchReverseSort = mkDefault false;
        searchSortColumn = mkDefault "type";
      };
      desktop.trashIconVisible = mkDefault true;
      plugins.disabledActions = [
        "add-desklets.nemo_action"
        "new-launcher.nemo_action"
        "change-background.nemo_action"
        "set-as-background.nemo_action"
        "mount-archive.nemo_action"
        "90_new-launcher.nemo_action"
        "set-resolution.nemo_action"
      ];
      windowState = {
        geometry = mkDefault "747x543+585+234";
        sidebarWidth = mkDefault 194;
        sidebarBookmarkBreakpoint = mkDefault 1;
      };
    };
    dconf.settings = {
      "org/cinnamon/desktop/media-handling" = {
        automount = mkDefault false;
        automount-open = mkDefault false;
        autorun-never = mkDefault true;
      };
      "org/cinnamon/desktop/privacy" = {
        remember-recent-files = mkDefault false;
      };
    };
  }];
}
