{config, lib, ...}:
let inherit (lib) escapeShellArg; in {
  boot.initrd.systemd.services.systemd-machine-id = {
    description = "Persistent Machine ID";
    serviceConfig.Type = "oneshot";
    before = ["initrd-switch-root.target"];
    wantedBy = ["sysinit.target"];
    unitConfig.RequiresMountsFor = "/sysroot/${config.system.stateDirectory'}";
    script = ''
      state_dir=${escapeShellArg "/sysroot/${config.system.stateDirectory'}"}
      if ! [ -f "$state_dir/machine-id" ]; then
        systemd-machine-id-setup --print > "$state_dir/machine-id"
      fi
      mkdir -p /sysroot/etc
      cp "$state_dir/machine-id" /sysroot/etc/machine-id
    '';
  };
  boot.initrd.systemd.suppressedUnits = ["systemd-machine-id-commit.service"];
  systemd.suppressedSystemUnits = ["systemd-machine-id-commit.service"];
}
