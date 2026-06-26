{config, lib, pkgs, ...}:
let inherit (lib) mkDefault mkIf;
in mkIf config.desktop'.profile.frankenstein.enable {
  home.packages = with pkgs; [nemo];
  dconf.settings = with lib.hm.gvariant; {
    "org/nemo/compact-view" = {
      all-columns-have-same-width = mkDefault true;
      default-zoom-level = mkDefault "small";
    };
    "org/nemo/desktop" = {
      trash-icon-visible = mkDefault true;
    };
    "org/nemo/icon-view" = {
      default-zoom-level = mkDefault "small";
    };
    "org/nemo/list-view" = {
      enable-folder-expansion = mkDefault true;
    };
    "org/nemo/plugins" = {
      disabled-actions = mkDefault [
        "add-desklets.nemo_action"
        "new-launcher.nemo_action"
        "change-background.nemo_action"
        "set-as-background.nemo_action"
        "mount-archive.nemo_action"
        "90_new-launcher.nemo_action"
        "set-resolution.nemo_action"
      ];
    };
    "org/nemo/preferences" = {
      close-device-view-on-device-eject = mkDefault false;
      date-font-choice = mkDefault "no-mono";
      date-format = mkDefault "iso";
      default-folder-viewer = mkDefault "list-view";
      default-sort-order = mkDefault "type";
      detect-content = mkDefault false;
      enable-delete = mkDefault false;
      inherit-folder-viewer = mkDefault true;
      quick-renames-with-pause-in-between = mkDefault false;
      show-hidden-files = mkDefault true;
      show-location-entry = mkDefault true;
      size-prefixes = mkDefault "base-2";
      thumbnail-limit = mkDefault (mkUint64 10485760);
    };
    "org/nemo/preferences/menu-config" = {
      background-menu-open-as-root = mkDefault false;
      background-menu-open-in-terminal = mkDefault true;
      selection-menu-favorite = mkDefault false;
      selection-menu-open-as-root = mkDefault false;
      selection-menu-pin = mkDefault false;
    };
    "org/nemo/search" = {
      search-reverse-sort = mkDefault false;
      search-sort-column = mkDefault "type";
    };
    "org/nemo/window-state" = {
      geometry = mkDefault "747x543+585+234";
      sidebar-width = mkDefault 194;
      sidebar-bookmark-breakpoint = mkDefault 1;
    };
    "org/cinnamon/desktop/media-handling" = {
      automount = mkDefault false;
      automount-open = mkDefault false;
      autorun-never = mkDefault true;
    };
    "org/cinnamon/desktop/privacy" = {
      remember-recent-files = mkDefault false;
    };
  };
}
