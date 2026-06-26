{config, lib, ...}:
let inherit (lib) mkIf mkDefault optionalString mapAttrsToList
                  mkOption concatLines concatMapAttrs pipe
                  toSentenceCase const mapAttrs;
    config' = config.networking.firewall';
    dhcpRules = ''
      ip version 4 udp sport 67 udp dport 68 accept
      ip6 daddr fe80::/64 udp sport 547 udp dport 546 accept
    '';
    tables = {
      rpFilter = {
        name = "rp-filter";
        description = "reverse path filtering";
        content = rules: ''
          type filter hook prerouting priority mangle - 25; policy drop
          ${dhcpRules}
          meta mark set ct mark
          ${rules}
          fib saddr . iif . mark check exists accept
        '';
        logDropped = true;
      };
      dnat = {
        description = "DNAT";
        content = rules: ''
          type nat hook prerouting priority dstnat
          ${rules}
        '';
      };
      ingress = {
        description = "ingress traffic";
        content = rules: ''
          type filter hook input priority filter + 10; policy drop
          iif lo accept
          ct state vmap {invalid: drop, established: accept, related: accept}
          ${dhcpRules}
          icmpv6 type {nd-neighbor-solicit, nd-router-advert, nd-neighbor-advert} accept
          ${rules}
        '';
        logDropped = true;
      };
      egress = {
        description = "engress traffic";
        content = rules: ''
          type filter hook output priority filter + 10
          ${rules}
        '';
      };
      route = {
        description = "policy routing";
        content = rules: ''
          type route hook output priority mangle + 10
          ${rules}
        '';
      };
      forward = {
        description = "traffic forwarding";
        content = rules: ''
          type filter hook forward priority filter + 10; policy drop
          ct state vmap {invalid: drop, established: accept, related: accept}
          ${rules}
        '';
        logDropped = true;
        chains =
          let private = ''{
                169.254.0.0/16, 192.168.0.0/16, 172.16.0.0/12,
                10.0.0.0/8, 100.64.0.0/10, 224.0.0.0/24, 239.0.0.0/8
              }'';
              private6 = "{fe80::/10, fc00::/7}";
          in {
            accept-if-internet = ''
              ip daddr ${private} return
              ip6 daddr ${private6} return
              ip6 daddr & f:: != e:: return
              accept
            '';
            accept-if-private = ''
              ip daddr ${private} accept
              ip6 daddr ${private6} accept
              ip6 daddr & f:: != e:: accept
            '';
          };
      };
      snat = {
        description = "SNAT";
        content = rules: ''
          type nat hook postrouting priority srcnat
          ${rules}
        '';
      };
    };
in {
  options.networking.firewall' = with lib.types; {
    enable = mkOption {
      description = "Whether to enable the custom firewall.";
      type = bool;
      default = true;
    };
  } // pipe tables [(concatMapAttrs (name: args: {
    ${name} = {
      rules = mkOption {
        description = "${toSentenceCase args.description} rules.";
        type = lines;
        default = "";
      };
      chains = mkOption {
        description = "${toSentenceCase args.description} chains.";
        type = attrsOf lines;
        default = {};
      };
      logDropped = mkOption {
        description = "Whether to log dropped packets.";
        type = bool;
        default = args.logDropped or false;
        readOnly = !(args ? logDropped);
      };
    };
  }))];
  config = {
    networking.nftables = mkIf config'.enable {
      enable = mkDefault true;
      tables = pipe tables [(concatMapAttrs (name: args:
        let displayName = args.name or name;
            inherit (config'.${name}) rules chains logDropped;
        in {
          "firewall.${displayName}" = {
            family = "inet";
            content = ''
              chain main {
                ${args.content rules}
                ${optionalString logDropped ''
                  log prefix "[firewall] [${displayName}] dropped: " level notice
                ''}
              }
              ${concatLines (pipe chains [(mapAttrsToList (name: rules: ''
                chain ${name} {
                  ${rules}
                }
              ''))])}
            '';
          };
        }))];
      # HACK: The check fails when there are references
      #       to yet-to-be-created interfaces.
      checkRuleset = mkDefault false;
    };
    networking.firewall' = pipe tables [(mapAttrs (name: table: {
      chains = mapAttrs (const mkDefault) (table.chains or {});
    }))];
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = mkDefault 1;
      "net.ipv6.conf.all.forwarding" = mkDefault 1;
      "net.ipv4.conf.all.accept_redirects" = mkDefault 0;
      "net.ipv4.conf.default.accept_redirects" = mkDefault 0;
      "net.ipv6.conf.all.accept_redirects" = mkDefault 0;
      "net.ipv6.conf.default.accept_redirects" = mkDefault 0;
    };
    # Disable NixOS's own firewall.
    networking.firewall.enable = mkIf config'.enable false;
    assertions = mkIf config'.enable [{
      assertion = !config.networking.firewall.enable;
      message = ''
        The NixOS firewall cannot be used
        together with the custom firewall.
      '';
    }];
  };
}
