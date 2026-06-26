{lib, config, ...}:
let stateDir = "${config.system.stateDirectory'}/passwords";
    inherit (lib) mkDefault mkOption mkIf;
in {
  options = with lib.types; {
    users.users = mkOption {
      type = attrsOf (submodule ({name, config, ...}: {
        config = mkIf ((name == "root" || config.isNormalUser) &&
                       config.hashedPassword == null &&
                       config.initialPassword == null &&
                       config.password == null) {
          hashedPasswordFile = mkDefault "${stateDir}/${name}";
        };
      }));
    };
  };
  config = {
    # FIXME: unescaped path
    systemd.tmpfiles.rules = ["z ${stateDir}/* 0600 root root"];
  };
}
