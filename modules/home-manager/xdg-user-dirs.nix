{lib, config, ...}:
let inherit (lib) mkDefault;
    personalDirectory = "/data/user/${config.home.username}/personal";
in {
  xdg.userDirs = {
    enable = mkDefault true;
    createDirectories = mkDefault false;
    desktop     = mkDefault "${personalDirectory}/Desktop";
    projects    = mkDefault "${personalDirectory}/Projects";
    documents   = mkDefault "${personalDirectory}/Documents";
    pictures    = mkDefault "${personalDirectory}/Pictures";
    music       = mkDefault "${personalDirectory}/Music";
    videos      = mkDefault "${personalDirectory}/Videos";
    download    = mkDefault "${personalDirectory}/Downloads";
    publicShare = mkDefault "${personalDirectory}/Public";
    templates   = mkDefault "${personalDirectory}/Templates";
  };
}
