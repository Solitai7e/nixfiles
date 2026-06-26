{lib, pkgs, config, ...}:
let inherit (lib) mkIf mkDefault mkOption
                  mkEnableOption mkPackageOption;
    config' = config.programs.gthumb';
in {
  options.programs.gthumb' = with lib.types; mkOption {
    type = submodule {
      freeformType = attrsOf anything;
      options = {
        enable = mkEnableOption "the gThumb image viewer";
        package = mkPackageOption pkgs "gthumb" {};
      };
    };
    default = {};
  };
  config = mkIf config'.enable {
    home.packages = [config'.package];
    dconf.gSettings' = {
      mappings = [{
        path = "org/gnome/gthumb";
        configPath = ["programs" "gthumb'"];
      }];
      packages = [config'.package];
    };
  };
  imports = [{
    programs.gthumb' = {
      browser = {
        folderTreeSortInverse = mkDefault false;
        scrollAction = mkDefault "zoom";
        showHiddenFiles = mkDefault true;
        sortType = mkDefault "file::name";
        viewerThumbnailsOrientation = mkDefault "vertical";
      };
      general = {
        activeExtensions = [
          "image_print" "search" "list_tools"
          "convert_format" "exiv2_tools" "edit_metadata"
          "find_duplicates" "rename_series" "change_date"
          "raw_files" "catalogs" "selections" "bookmarks"
          "file_manager" "slideshow"
        ];
        storeMetadataInFiles = mkDefault false;
      };
      imageViewer.zoomChange = mkDefault "keep-prev";
    };
  }];
}
