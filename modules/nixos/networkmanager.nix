{config, lib, ...}:
let inherit (lib) mkIf;
in mkIf config.networking.networkmanager.enable {
  systemd.tmpfiles.rules =
    ["d /data/state/networkmanager/system-connections 0700 root root"];
  systemd.services.NetworkManager.serviceConfig.BindPaths =
    "/data/state/networkmanager/system-connections:/etc/NetworkManager/system-connections";
}
