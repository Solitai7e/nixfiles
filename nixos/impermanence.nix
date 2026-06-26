{lib, config, ...}:
let inherit (lib) mkIf mkOption mkEnableOption mkMerge optionalAttrs
                  escapeShellArg escapeShellArgs attrValues head;
    config' = config.impermanence';
in {
  options.impermanence' = with lib.types; {
    enable = mkEnableOption "impermanence";
    method = mkOption {
      description = "How Impermanence should be implemented.";
      type = attrTag {
        tmpfs = mkOption {
          description = "Mount a tmpfs as /";
          type = enum [true];
        };
        format = mkOption {
          description = "Format a block device on boot.";
          type = submodule ({config, ...}: {
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
              configure = mkOption {
                type = anything;
                readOnly = true;
                default.script = ''
                  ${escapeShellArgs (["mkfs.${config.fsType}" config.device] ++ config.args)}
                '';
              };
            };
          });
        };
        btrfs = mkOption {
          description = "Delete a btrfs subvolume on boot.";
          type = submodule ({config, ...}: {
            options = {
              device = mkOption {
                description = "Block device with the btrfs partition.";
                type = str;
              };
              deleteSubvol = mkOption {
                description = "The subvolume to delete.";
                type = str;
              };
              configure = mkOption {
                type = anything;
                readOnly = true;
                visible = false;
                default.script = ''
                  device=${escapeShellArg config.device}
                  subvol=${escapeShellArg config.deleteSubvol}
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
      (let method = head (attrValues config'.method);
       in optionalAttrs (method != true) method.configure)
      {
        description = "Reset Root Volume for Impermanence";
        serviceConfig.Type = "oneshot";
        serviceConfig.SyslogIdentifier = "impermanence";
        after = ["local-fs-pre.target" "initrd-root-device.target"];
        before = ["sysroot.mount"];
        wantedBy = ["initrd-root-device.target"];
      }
    ];
  };
}
