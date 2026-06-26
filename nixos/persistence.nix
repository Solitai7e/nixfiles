{lib, config, ...}:
let inherit (lib) mkOption; in {
  options.system = with lib.types; {
    dataDirectory' = mkOption {
      description = "Mountpoint for the persistent data volume.";
      type = externalPath;
      default = "/data";
    };
    configDirectory' = mkOption {
      description = "Location of the system configuration.";
      type = externalPath;
      default = "${config.system.dataDirectory'}/config";
      readOnly = true;
    };
    stateDirectory' = mkOption {
      description = "Location under which to store persistent system state.";
      type = externalPath;
      default = "${config.system.dataDirectory'}/state";
      readOnly = true;
    };
    usersDirectory' = mkOption {
      description = "Location in which per-user data directories will be created.";
      type = externalPath;
      default = "${config.system.dataDirectory'}/per-user";
      readOnly = true;
    };
  };
  config = {
    fileSystems."${config.system.dataDirectory'}".neededForBoot = true;
  };
}
