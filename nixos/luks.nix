{lib, config, ...}:
let inherit (lib) mkDefault mkOption mkMerge mkIf pipe mapAttrsToList;
    secretsDir = "${config.system.stateDirectory'}/luks";
in {
  options = with lib.types; {
    boot.initrd.luks.devices = mkOption {
      type = attrsOf (submodule ({name, ...}: {
        config.keyFile = mkDefault "/etc/luks-auto-secrets/${name}.key";
      }));
    };
  };
  config = {
    boot.initrd.secrets = mkMerge (pipe config.boot.initrd.luks.devices [
      (mapAttrsToList (name: {keyFile, ...}: {
        ${keyFile} = mkIf (keyFile == "/etc/luks-auto-secrets/${name}.key")
          "${secretsDir}/${name}.key";
      }))
    ]);
    systemd.tmpfiles.rules = ["z ${secretsDir}/* 0600 root root"];
    boot.loader.grub.enableCryptodisk = true;
  };
}
