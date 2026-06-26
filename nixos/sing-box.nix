{lib, pkgs, config, ...}:
let inherit (lib) mkOption mkEnableOption mkPackageOption
                  mkDefault mkIf getExe;
    inherit (pkgs) writeTextDir writeText;
    inherit (pkgs.writers) writeJSON;
    config' = config.services.sing-box';
in {
  options.services.sing-box' = with lib.types; {
    enable = mkEnableOption "sing-box";
    package = mkPackageOption pkgs "sing-box" {};
    settings = mkOption {
      description = "sing-box configuration.";
      type = submodule { freeformType = (pkgs.formats.json {}).type; };
    };
  };
  config = mkIf config'.enable {
    services.sing-box'.settings = {
      log.level = mkDefault "warn";
      inbounds = mkDefault [];
      outbounds = [{
        tag = "direct";
        type = "direct";
      }];
      route.auto_detect_interface = false;
      route.default_interface = "gateway";
    };
    systemd.services.sing-box =
      let configFile = writeJSON "sing-box-config.json" config'.settings; in {
        description = "sing-box - The Universal Proxy Platform";
        bindsTo = ["sing-box-netns.service"];
        after = ["network-online.target" "sing-box-netns.service"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "exec";
          ExecStart = "${getExe config'.package} -c ${configFile} run";
          RestrictAddressFamilies = ["AF_NETLINK"];
          NetworkNamespacePath = "/run/netns/sing-box";
        };
        hardening' = {
          enable = true;
          rootFs.inputs = [config'.package configFile];
          rootFs.links = [(writeTextDir "etc/resolv.conf" ''
            nameserver 172.17.77.1
          '')];
        };
      };
    systemd.services.sing-box-netns = {
      description = "Network Isolation for sing-box";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig.Type = "oneshot";
      serviceConfig.RemainAfterExit = true;
      path = [pkgs.iproute2];
      script = ''
        ip netns delete sing-box || :
        ip -echo netns add sing-box
        ip -echo link add dev sing-box type veth peer name gateway netns sing-box
        ip -echo -4 address add dev sing-box 172.17.77.1/31
        ip -echo -6 address add dev sing-box fdfd:993b:4424::1/127
        ip -echo -n sing-box -4 address add dev gateway 172.17.77.0/31
        ip -echo -n sing-box -6 address add dev gateway fdfd:993b:4424::/127
        ip -echo link set up dev sing-box
        ip -echo -n sing-box link set up dev gateway
        ip -echo -n sing-box -4 route add default via 172.17.77.1 dev gateway
        ip -echo -n sing-box -6 route add default via fdfd:993b:4424::1 dev gateway
        ip -echo -n sing-box link set up dev lo
      '';
      serviceConfig.ExecStopPost =
        ["-${pkgs.iproute2}/bin/ip -echo netns delete sing-box"];
      unitConfig.StopWhenUnneeded = true;
    };
    systemd.services.sing-box-dns = {
      description = "Forward DNS Queries from sing-box";
      wantedBy = ["sing-box-netns.service"];
      after = ["sing-box-netns.service"];
      serviceConfig = {
        Type = "forking";
        GuessMainPID = true;
        ExecStart = "${getExe pkgs.aardvark-dns} -p 53 -c /tmp run";
        PrivatePIDs = false;
        PrivateUsers = false;
        PrivateNetwork = false;
        CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE"];
        AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
        SocketBindDeny = "any";
        SocketBindAllow = "53";
        BindReadOnlyPaths = [
          "${writeText "aardvark-dns-config" "172.17.77.1\n"}:/tmp/config"
          "/etc/resolv.conf"
        ];
      };
      hardening' = {
        enable = true;
        rootFs.inputs = [pkgs.aardvark-dns];
      };
      unitConfig.StopWhenUnneeded = true;
    };
    networking.firewall'.rules = {
      ingress = "iifname sing-box meta l4proto {tcp, udp} th dport 53 accept";
      forward = "iifname sing-box jump forward-to-internet";
      snat = "iifname sing-box masquerade";
    };
    assertions = [{
      assertion = !config.services.sing-box.enable;
      message = ''
        services.sing-box and services.sing-box'
        cannot be enabled at the same time.
      '';
    }];
  };
}
