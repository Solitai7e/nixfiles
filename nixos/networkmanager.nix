{config, lib, ...}:
let stateDir = "${config.system.stateDirectory'}/networkmanager";
    inherit (lib) mkIf;
in mkIf config.networking.networkmanager.enable {
  systemd.tmpfiles.rules =
    ["d ${stateDir}/system-connections 0700 root root"];
  systemd.services.NetworkManager.serviceConfig.BindPaths =
    "${stateDir}/system-connections:/etc/NetworkManager/system-connections";
}
