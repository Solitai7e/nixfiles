{
  boot.initrd.systemd.services.systemd-machine-id = {
    description = "Persistent Machine ID";
    serviceConfig.Type = "oneshot";
    before = ["initrd-switch-root.target"];
    wantedBy = ["sysinit.target"];
    unitConfig.RequiresMountsFor = "/sysroot/data";
    script = ''
      if ! [ -f "$state_dir/machine-id" ]; then
        systemd-machine-id-setup --print > /sysroot/data/machine-id
      fi
      mkdir -p /sysroot/etc
      cp /sysroot/data/machine-id /sysroot/etc/machine-id
    '';
  };
  boot.initrd.systemd.suppressedUnits = ["systemd-machine-id-commit.service"];
  systemd.suppressedSystemUnits = ["systemd-machine-id-commit.service"];
}
