{config, lib, ...}:
let inherit (lib) mkIf mkDefault mkOption optionalString;
    mkDisableOption = name: with lib.types; mkOption {
      description = "Whether to enable ${name}.";
      type = bool;
      default = true;
    };
    config' = config.networking.firewall';
in {
  options.networking.firewall' = with lib.types; {
    enable = mkDisableOption "the custom firewall";
    rules = {
      dnat = mkOption {
        description = "DNAT rules.";
        type = lines;
        default = "";
      };
      ingress = mkOption {
        description = "Ingress traffic rules.";
        type = lines;
        default = "";
      };
      forward = mkOption {
        description = "Traffic forwarding rules.";
        type = lines;
        default = "";
      };
      egress = mkOption {
        description = "Egress traffic rules.";
        type = lines;
        default = "";
      };
      snat = mkOption {
        description = "SNAT rules.";
        type = lines;
        default = "";
      };
    };
    logDropped = mkDisableOption "logging of dropped packets";
  };
  config = mkIf config'.enable {
    networking.nftables.enable = mkDefault true;
    networking.nftables.tables.firewall = {
      family = "inet";
      content = ''
        define private = {
          169.254.0.0/16, 192.168.0.0/16, 172.16.0.0/12,
          10.0.0.0/8, 100.64.0.0/10, 224.0.0.0/24, 239.0.0.0/8
        }
        define private6 = {fe80::/10, fc00::/7}

        chain rp-filter {
          type filter hook prerouting priority raw; policy drop
          ip version 4 udp dport 68 accept comment "DHCP"
          ip6 daddr fe80::/64 udp dport 546 accept comment "DHCPv6"
          fib saddr . iif . mark check exists accept
          ${optionalString config'.logDropped ''log prefix "[firewall] [rp-filter] dropped: "''}
        }
        chain dstnat {
          type nat hook prerouting priority dstnat
          ${config'.rules.dnat}
        }
        chain ingress {
          type filter hook input priority filter; policy drop
          iif lo accept
          ct state vmap {invalid: drop, established: accept, related: accept}
          icmpv6 type {nd-neighbor-solicit, nd-router-advert, nd-neighbor-advert} accept comment "NDP"
          ${config'.rules.ingress}
          ${optionalString config'.logDropped ''log prefix "[firewall] [ingress] dropped: "''}
        }
        chain forward {
          type filter hook forward priority filter; policy drop
          ct state vmap {invalid: drop, established: accept, related: accept}
          ${config'.rules.forward}
          ${optionalString config'.logDropped ''log prefix "[firewall] [forward] dropped: "''}
        }
        chain forward-to-internet {
          ip daddr $private return
          ip6 daddr $private6 return
          ip6 daddr & f:: != e:: return
          accept
        }
        chain forward-to-private {
          ip daddr $private accept
          ip6 daddr $private6 accept
          ip6 daddr & f:: != e:: accept
        }
        chain egress {
          type filter hook output priority filter
          ${config'.rules.egress}
        }
        chain srcnat {
          type nat hook postrouting priority srcnat
          ${config'.rules.snat}
        }
      '';
    };
    # HACK: The check fails when there are references
    #       to yet-to-be-created interfaces.
    networking.nftables.checkRuleset = mkDefault false;
    # Disable NixOS's own firewall.
    networking.firewall.enable = mkDefault false;
    assertions = [{
      assertion = !config.networking.firewall.enable;
      message = ''
        The NixOS firewall cannot be used together
        with the custom firewall.
      '';
    }];

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = mkDefault 1;
      "net.ipv6.conf.all.forwarding" = mkDefault 1;
      "net.ipv4.conf.all.accept_redirects" = mkDefault 0;
      "net.ipv4.conf.default.accept_redirects" = mkDefault 0;
      "net.ipv6.conf.all.accept_redirects" = mkDefault 0;
      "net.ipv6.conf.default.accept_redirects" = mkDefault 0;
    };
  };
}
