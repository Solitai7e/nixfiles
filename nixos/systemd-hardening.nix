{lib, pkgs, ...}:
let inherit (lib) mkDefault mkOption mkIf mkEnableOption escapeShellArg;
    inherit (pkgs) symlinkJoin writeClosure;
in {
  options.systemd.services = with lib.types; mkOption {
    type = attrsOf (submodule ({config, ...}: {
      options.hardening' = {
        enable = mkEnableOption "service hardening options";
        rootFs.inputs = mkOption {
          description = "Store paths to copy to the service's root image.";
          type = listOf path;
          default = [];
        };
        rootFs.links = mkOption {
          description = ''
            Packages to create links for in the service's root
            image. Implicitly added to hardening'.inputs.
          '';
          type = listOf path;
          default = [];
        };
      };
      config.hardening'.rootFs.inputs = config.hardening'.rootFs.links;
      config.serviceConfig = mkIf config.hardening'.enable {
        DynamicUser = mkDefault true;
        PrivateUsers = mkDefault true;
        PrivateMounts = mkDefault true;
        RootDirectory = mkDefault (symlinkJoin {
          name = "${config.name}-rootfs";
          paths = config.hardening'.rootFs.links;
          postBuild = ''
            closure=${escapeShellArg (writeClosure config.hardening'.rootFs.inputs)}
            mkdir -p "$out"
            xargs -r -d "\n" -- cp -vR -t "$out" --parents < "$closure"
          '';
        });
        RootEphemeral = mkDefault true;
        PrivateTmp = mkDefault "disconnected";
        ProtectSystem = mkDefault "strict";
        ProtectHome = mkDefault true;
        InaccessiblePaths = ["+/sys"];
        PrivatePIDs = mkDefault true;
        ProtectProc = mkDefault "invisible";
        ProcSubset = mkDefault "pid";
        PrivateDevices = mkDefault true;
        PrivateNetwork = mkDefault true;
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
        SystemCallErrorNumber = mkDefault "EPERM";
        SystemCallFilter = [
          "@basic-io" "@file-system" "@sync" "@io-event"
          "@network-io" "@signal" "@process" "pipe2"
        ];
      };
    }));
  };
}
