{lib, ...}:
let inherit (lib) mkDefault; in {
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = mkDefault true;
    device = "nodev";
    timeoutStyle = "hidden";
  };
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  fileSystems."/boot/efi" = {
    fsType = "vfat";
    options = ["fmask=0133" "dmask=0022"];
  };
}
