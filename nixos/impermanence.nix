{lib, config, ...}:
let inherit (lib) mkIf mkOption mkEnableOption mkMerge head
                  escapeShellArg escapeShellArgs attrValues;
    config' = config.boot.initrd.services.impermanence';
in {
  options.boot.initrd.services.impermanence' = with lib.types; {
    enable = mkEnableOption ''
      a helper task executed during boot to enforce impermanence
    '';
    method = mkOption {
      description = "How Impermanence should be implemented.";
      type = attrTag {
        format = mkOption {
          description = "Format a block device on boot.";
          type = submodule (args: {
            options = {
              device = mkOption {
                description = "The block device to format.";
                type = externalPath;
              };
              fsType = mkOption {
                description = "Filesystem to format the device to.";
                type = str;
              };
              args = mkOption {
                description = "Additional args for the mkfs.* command";
                type = listOf str;
                default = [];
              };
              service' = mkOption {
                type = attrsOf anything;
                visible = false;
                readOnly = true;
                default.script =
                  let inherit (args.config) fsType device args;
                  in escapeShellArgs (["mkfs.${fsType}" device] ++ args);
              };
            };
          });
        };
        btrfs = mkOption {
          description = "Delete a btrfs subvolume on boot.";
          type = submodule (args: {
            options = {
              device = mkOption {
                description = "Block device with the btrfs partition.";
                type = str;
              };
              deleteSubvol = mkOption {
                description = "The subvolume to delete.";
                type = str;
              };
              service' = mkOption {
                type = attrsOf anything;
                readOnly = true;
                visible = false;
                default.script = ''
                  device=${escapeShellArg args.config.device}
                  subvol=${escapeShellArg args.config.deleteSubvol}
                  mountpoint="$(mktemp -d)"
                  mount -v -o noatime "$device" "$mountpoint"
                  trap 'umount -v "$mountpoint"' EXIT INT TERM HUP
                  btrfs -v subvolume delete --recursive "$mountpoint/$subvol"
                  btrfs -v subvolume create "$mountpoint/$subvol"
                '';
              };
            };
          });
        };
      };
    };
  };
  config = mkIf config'.enable {
    boot.initrd.systemd.services.impermanence = mkMerge [
      (head (attrValues config'.method)).service'
      {
        description = "Impermanence Helper";
        serviceConfig.Type = "oneshot";
        serviceConfig.SyslogIdentifier = "impermanence";
        after = ["local-fs-pre.target" "initrd-root-device.target"];
        before = ["sysroot.mount"];
        wantedBy = ["initrd-root-device.target"];
      }
    ];
  };
}
