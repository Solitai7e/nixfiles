{lib, pkgs, config, utils, ...}:
let inherit (lib) mkOption mkEnableOption mkPackageOption mkIf
                  getExe mkDefault removeAttrs escapeShellArg;
    inherit (utils) escapeSystemdExecArgs;
    inherit (pkgs.writers) writeJSON;
    config' = config.services.yggdrasil';
in {
  options.services.yggdrasil' = with lib.types; {
    enable = mkEnableOption "Yggdrasil";
    package = mkPackageOption pkgs "yggdrasil" {};
    settings = mkOption {
      description = "Yggdrasil configuration.";
      type = submodule { freeformType = (pkgs.formats.json {}).type; };
      default = {};
    };
    extraArgs = mkOption {
      description = "Extra startup arguments for the Yggdrasil service.";
      type = listOf str;
      default = [];
    };
  };
  config =
    let inherit (config') settings extraArgs;
        args = ["-useconffile" configFile] ++ extraArgs;
        configFile = writeJSON "yggdrasil.conf" (
          if settings.PrivateKeyPath != null
            then settings // { PrivateKeyPath = "/run/yggdrasil.key"; }
            else removeAttrs settings "PrivateKeyPath");
    in mkIf config'.enable {
      environment.systemPackages = [config'.package];
      services.yggdrasil'.settings = {
        IfName = mkDefault "yggdrasil";
        Listen = [];
        MulticastInterfaces = [];
        PrivateKeyPath = mkDefault "${config.system.stateDirectory'}/yggdrasil.key";
      };
      systemd.services = {
        yggdrasil = {
          description = "Yggdrasil Network";
          wants = ["network.target"];
          before = ["network.target"];
          after = ["network-pre.target"];
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            Type = "exec";
            ExecStart = escapeSystemdExecArgs ([(getExe config'.package)] ++ args);
            PrivateUsers = false;
            PrivateDevices = false;
            DeviceAllow = ["/dev/net/tun"];
            CapabilityBoundingSet = ["CAP_NET_ADMIN"];
            AmbientCapabilities = ["CAP_NET_ADMIN"];
            RestrictAddressFamilies = ["AF_UNIX" "AF_NETLINK"];
            RuntimeDirectory = "yggdrasil";
            LoadCredential = ["private-key:${settings.PrivateKeyPath}"];
            BindReadOnlyPaths = [
              "%d/private-key:/run/yggdrasil.key"
              "/etc/resolv.conf"
            ];
            SystemCallFilter = [
              "@basic-io" "@file-system" "@sync" "@io-event"
              "@network-io" "@signal" "@process" "ioctl" "pipe2"
            ];
          };
          hardening' = {
            enable = true;
            filesystem.packages = [config'.package configFile];
            network.mode = "host";
          };
        };
        yggdrasil-private-key = mkIf (settings.PrivateKeyPath != null) {
          description = "Private Key for Yggdrasil";
          wantedBy = ["yggdrasil.service"];
          before = ["yggdrasil.service"];
          serviceConfig.Type = "oneshot";
          path = [config'.package];
          script = ''
            out=${escapeShellArg settings.PrivateKeyPath}
            [ -f "$out" ] && exit 0
            yggdrasil -genconf | yggdrasil -useconf -exportkey > "$out"
            chmod -v 0600 "$out"
            chown -v root:root "$out"
          '';
        };
      };
      networking.firewall' = {
        rpFilter.rules = "ip6 saddr 200::/7 iifname != ${settings.IfName} drop";
        egress.rules = "ip6 daddr 200::/7 oifname != ${settings.IfName} drop";
        ingress.rules = mkIf (settings.MulticastInterfaces != []) ''
          ip6 daddr ff02::114 udp dport 9001 accept
        '';
      };
      assertions = [{
        assertion = !config.services.yggdrasil.enable;
        message = ''
          This module cannot be used alongside
          NixOS's own Yggdrasil module.
        '';
      }];
    };
}
