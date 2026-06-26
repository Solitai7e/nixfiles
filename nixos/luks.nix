{lib, config, ...}:
let stateDir = "${config.system.stateDirectory'}/luks";
    inherit (lib) mkDefault mkOption mkMerge mkIf pipe mapAttrsToList;
    inherit (config.boot.initrd.luks) devices;
in {
  options = with lib.types; {
    boot.initrd.luks.devices = mkOption {
      type = attrsOf (submodule ({name, ...}: {
        config.keyFile = mkDefault "/${name}.secret";
      }));
    };
  };
  config = {
    boot.initrd.secrets = mkMerge (pipe devices [
      (mapAttrsToList (name: {keyFile, ...}: mkIf (keyFile == "/${name}.secret") {
        ${keyFile} = "${stateDir}/${name}.key";
      }))
    ]);
    # FIXME: unescaped path
    systemd.tmpfiles.rules = ["z ${stateDir}/* 0600 root root"];
    boot.loader.grub.enableCryptodisk = true;
  };
}
