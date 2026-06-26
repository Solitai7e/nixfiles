{lib, config, ...}:
let inherit (lib) mkDefault; in {
  xdg.userDirs = {
    enable = mkDefault true;
    createDirectories = mkDefault false;
    desktop     = mkDefault "${config.home.personalDirectory'}/Desktop";
    projects    = mkDefault "${config.home.personalDirectory'}/Projects";
    documents   = mkDefault "${config.home.personalDirectory'}/Documents";
    pictures    = mkDefault "${config.home.personalDirectory'}/Pictures";
    music       = mkDefault "${config.home.personalDirectory'}/Music";
    videos      = mkDefault "${config.home.personalDirectory'}/Videos";
    download    = mkDefault "${config.home.personalDirectory'}/Downloads";
    publicShare = mkDefault "${config.home.personalDirectory'}/Public";
    templates   = mkDefault "${config.home.personalDirectory'}/Templates";
  };
}
