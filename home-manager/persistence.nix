{systemConfig, config, lib, pkgs, ...}:
let inherit (lib) mkOption escapeShellArg hm; in {
  options.home = with lib.types; {
    dataDirectory' = mkOption {
      default = "${systemConfig.system.usersDirectory'}/${config.home.username}";
      type = externalPath;
      readOnly = true;
    };
    configDirectory' = mkOption {
      default = "${config.home.dataDirectory'}/config";
      type = externalPath;
      readOnly = true;
    };
    stateDirectory' = mkOption {
      default = "${config.home.dataDirectory'}/state";
      type = externalPath;
      readOnly = true;
    };
    personalDirectory' = mkOption {
      default = "${config.home.dataDirectory'}/personal";
      type = externalPath;
      readOnly = true;
    };
  };
  config = {
    home.activation = with hm.dag; {
      linkActivationScript = entryAfter ["writeBoundary"] ''
        run ln $VERBOSE_ARG -sfnT \
               "$(readlink -f "$BASH_SOURCE")" \
               ${escapeShellArg "${config.home.stateDirectory'}/activate"}
      '';
    };
  };
}
