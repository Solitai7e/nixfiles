{lib, ...}:
let inherit (lib) mkIf mkDefault mkOption; in {
  options = with lib.types; {
    users.users = mkOption {
      type = attrsOf (submodule (args: let subconfig = args.config; in {
        config.hashedPasswordFile = mkIf (
          (subconfig.isNormalUser || subconfig.name == "root") &&
          subconfig.hashedPassword == null &&
          subconfig.initialPassword == null &&
          subconfig.password == null)
            (mkDefault "/data/state/passwords/${subconfig.name}");
      }));
    };
  };
  config = {
    systemd.tmpfiles.rules = ["z /data/state/passwords/* 0600 root root"];
  };
}
