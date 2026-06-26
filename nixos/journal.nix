{config, ...}: {
  fileSystems."/var/log/journal" = {
    device = "${config.system.stateDirectory'}/journal";
    fsType = "none";
    options = ["bind" "x-systemd.before=systemd-journald.service"];
  };
}
