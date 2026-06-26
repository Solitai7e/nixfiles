{lib, ...}:
let inherit (lib) mkDefault mkOption mkIf mkEnableOption; in {
  options.systemd.services = with lib.types; mkOption {
    type = attrsOf (submodule ({config, ...}: {
      options.hardening'.enable = mkEnableOption "service hardening";
      config.serviceConfig = mkIf config.hardening'.enable {
        DynamicUser = mkDefault true;
        PrivateUsers = mkDefault true;
        PrivateMounts = mkDefault true;
        PrivateTmp = mkDefault "disconnected";
        ProtectSystem = mkDefault "strict";
        ProtectHome = mkDefault true;
        PrivatePIDs = mkDefault true;
        ProtectProc = mkDefault "invisible";
        ProcSubset = mkDefault "pid";
        PrivateDevices = mkDefault true;
        DevicePolicy = mkDefault "closed";
        PrivateIPC = mkDefault true;
        ProtectHostname = mkDefault true;
        ProtectClock = mkDefault true;
        ProtectControlGroups = mkDefault true;
        ProtectKernelTunables = mkDefault true;
        ProtectKernelModules = mkDefault true;
        ProtectKernelLogs = mkDefault true;
        BindLogSockets = mkDefault false;
        CapabilityBoundingSet = mkDefault "";
        AmbientCapabilities = mkDefault "";
        NoNewPrivileges = mkDefault true;
        RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
        MemoryDenyWriteExecute = mkDefault true;
        RestrictSUIDSGID = mkDefault true;
        RestrictNamespaces = mkDefault true;
        RestrictRealtime = mkDefault true;
        LockPersonality = mkDefault true;
        RemoveIPC = mkDefault true;
        SystemCallArchitectures = mkDefault "native";
        SystemCallErrorNumber = mkDefault "ENOSYS";
        SystemCallFilter = mkDefault ["~@known"];
      };
    }));
  };
}
