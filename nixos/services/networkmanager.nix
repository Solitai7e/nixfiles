{config, lib, ...}:
let inherit (lib) mkIf;
in mkIf config.networking.networkmanager.enable {
  boot.initrd.systemd.tmpfiles.settings."70-persistence" = {
    "/sysroot/data/state/networkmanager/system-connections".d = {
      mode = "0755";
      user = "root";
      group = "root";
    };
    "/sysroot/data/state/networkmanager/system-connections/*".z = {
      mode = "0600";
      user = "root";
      group = "root";
    };
  };
  systemd.services.NetworkManager.serviceConfig.BindPaths =
    "/data/state/networkmanager/system-connections:/etc/NetworkManager/system-connections";
}
