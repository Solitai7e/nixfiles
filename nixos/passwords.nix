{lib, config, ...}:
let inherit (lib) mkIf mkDefault mkOption;
    passwordsDir = "${config.system.stateDirectory'}/passwords";
in {
  options = with lib.types; {
    users.users = mkOption {
      type = attrsOf (submodule (args: let subconfig = args.config; in {
        config.hashedPasswordFile = mkIf (
          (subconfig.isNormalUser || subconfig.name == "root") &&
          subconfig.hashedPassword == null &&
          subconfig.initialPassword == null &&
          subconfig.password == null
        )
          (mkDefault "${passwordsDir}/${subconfig.name}");
      }));
    };
  };
  config = {
    systemd.tmpfiles.rules = ["z ${passwordsDir}/* 0600 root root"];
  };
}
