{lib, config, ...}:
let inherit (lib) mkDefault optional match pipe concatMapAttrs optionalAttrs;
    isSystemEncrypted = [] != pipe config.fileSystems."/".device [
      (match "/dev/mapper/([^/]+)")
      (map (name: optional (config.boot.initrd.luks.devices ? name) null))
    ];
in {
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = mkDefault true;
    device = "nodev";
    enableCryptodisk = isSystemEncrypted;
    timeoutStyle = "hidden";
  };
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  fileSystems."/" = {
    fsType = "btrfs";
    options = ["subvol=root" "noatime"];
  };
  fileSystems."/boot" = {
    inherit (config.fileSystems."/") device fsType;
    options = ["subvol=boot" "noatime"];
  };
  fileSystems."/data" = {
    inherit (config.fileSystems."/") device fsType;
    options = ["subvol=data" "noatime"];
  };
  fileSystems."/boot/efi" = {
    fsType = "vfat";
    options = ["fmask=0133" "dmask=0022"];
  };

  boot.initrd.secrets = pipe config.boot.initrd.luks.devices [
    (concatMapAttrs (device: {keyFile, ...}:
      optionalAttrs (keyFile != null) { ${keyFile} = keyFile; }))
  ];
}
