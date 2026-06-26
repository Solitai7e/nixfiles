{lib, systemConfig, config, ...}:
let inherit (lib) mkOption; in {
  options = with lib.types; {
    home.dataDirectory' = mkOption {
      description = ''
        Location of the user's persistent data directory.
      '';
      type = str;
      default = "/data/per-user/${config.home.username}";
      readOnly = true;
    };
  };
  config = {
    home.homeDirectory =
      systemConfig.users.users.${config.home.username}.home;
  };
}
