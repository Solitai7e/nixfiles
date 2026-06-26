{lib, pkgs, config, ...}:
let inherit (lib) mkOption mkIf mkMerge getExe getAttr mapAttrsToList pipe
                  elem filterAttrs mapAttrs nameValuePair genAttrs' readFile;
    inherit (pkgs) writeText writeTextDir runCommand;
    inherit (pkgs.writers) writePython3 writeJSON;
    config' = config.systemd.hardening'.network;
in {
  options.systemd = with lib.types; {
    hardening'.network = {
      ifName = mkOption {
        description = ''
          Name of the network bridge created for
          network-isolated services.
        '';
        type = str;
        default = "isolated";
      };
    } // genAttrs' ["4" "6"] (v: nameValuePair "ipv${v}" {
      subnet = mkOption {
        description = "IPv${v} subnet to allocate to network-isolated services.";
        type = str;
        default = getAttr v {
          "4" = "10.80.0.0/16";
          "6" = "fddd:14f1:d4b5:7248::/64";
        };
      };
      gateway = mkOption {
        description = ''
          IPv${v} gateway for network-isolated services.
          Defaults to the first host address of the subnet.
        '';
        type = nullOr str;
        default = null;
      };
    });
    services = mkOption {
      type = attrsOf (submodule (args@{name, ...}:
        let subconfig = args.config; in {
          options.hardening'.network = {
            mode = mkOption {
              description = "Network isolation mode for the service.";
              type = enum ["host" "isolated" "disconnected"];
              default = "disconnected";
            };
            ifName = mkOption {
              description = ''
                Name of the virtual ethernet
                adapter to create for the service.
              '';
              type = nullOr str;
            };
            addresses = mkOption {
              description = "IP address(es) to assign to the service.";
              type = listOf str;
              default = [];
            };
            #publishPorts = mkOption {
            #  description = "List of ports to publish to the host.";
            #  type = listOf str;
            #  default = [];
            #};
          };
          config =
            let subconfig' = subconfig.hardening'.network;
            in mkIf subconfig.hardening'.enable (mkMerge [
              (mkIf (subconfig'.mode == "host") {
                serviceConfig.BindReadOnlyPaths = ["/etc/resolv.conf"];
              })
              (mkIf (elem subconfig'.mode ["disconnected" "isolated"]) {
                serviceConfig.PrivateNetwork = true;
              })
              (mkIf (subconfig'.mode == "isolated") {
                bindsTo = ["systemd-network-isolation@%N.service"];
                after = ["systemd-network-isolation@%N.service"];
                serviceConfig.NetworkNamespacePath = "/run/netns/%n";
              })
            ]);
      }));
    };
  };
  config =
    let subconfigs' = pipe config.systemd.services [
          (filterAttrs (name: service: service.hardening'.enable))
          (mapAttrs (name: service: service.hardening'.network))
        ];
        generate-configs = writePython3 "generate-configs" { doCheck = false; } ''
          import sys, json, shlex
          from pathlib import Path
          from ipaddress import ip_network, ip_address

          def shlex_vars(dict):
            expr = ""
            for name, value in dict.items():
              if isinstance(value, list):
                expr += f"{name}={shlex.join(map(str, value))}\n"
              else:
                expr += f"{name}={shlex.quote(str(value))}\n"
            return expr

          out = Path(sys.argv[1])
          intermediate_config = json.loads(Path(sys.argv[2]).read_text())

          subnet = {}; gateway = {}; static_addrs = {}; dynamic_addrs = {}
          for v in 4, 6:
            subnet[v] = ip_network(intermediate_config[f"ipv{v}"]["subnet"])
            match intermediate_config[f"ipv{v}"]["gateway"]:
              case None: gateway[v] = subnet[v][1]
              case addr: gateway[v] = ip_address(addr)
            static_addrs[v] = set([gateway[v]])
            dynamic_addrs[v] = (
              addr for addr in subnet[v].hosts()
              if not addr in static_addrs[v])
          for subconfig in intermediate_config["subconfigs"].values():
            for addr in map(ip_address, subconfig["addresses"]):
              static_addrs[addr.version].add(addr)

          out.mkdir(mode = 0o755, exist_ok = True)
          (out / "config").write_text(shlex_vars({
            "master": intermediate_config["ifName"],
            "gateway": gateway[4],
            "gateway6": gateway[6],
            "cidr": subnet[4].prefixlen,
            "cidr6": subnet[6].prefixlen}))

          (out / "resolv.conf").write_text("".join([
            f"nameserver {gateway[4]}\n"
            f"nameserver {gateway[6]}\n"]))
          (out / "aardvark-dns-config").write_text(f"{gateway[4]} {gateway[6]}")

          (out / "service-configs").mkdir(mode = 0o755, exist_ok = True)
          for service, subconfig in intermediate_config["subconfigs"].items():
            addrs = {4: [], 6: []}
            for addr in map(ip_address, subconfig["addresses"]):
              addrs[addr.version].append(addr)
            (out / "service-configs" / f"{service}.conf").write_text(shlex_vars({
              "dev": subconfig.get("ifName"),
              "addrs": addrs[4] or [next(dynamic_addrs[4])],
              "addrs6": addrs[6] or [next(dynamic_addrs[6])]}))
        '';
        configDir = runCommand "systemd-network-isolation-configs" {} ''
          ${generate-configs} "$out" ${writeJSON "intermediate" (config' // {
            subconfigs = subconfigs';
          })}
        '';
    in {
      systemd.packages = pipe subconfigs' [(mapAttrsToList (service: subconfig':
        let dropInFile = "lib/systemd/system/${service}.service.d/" +
                         "systemd-network-isolation.conf";
        in mkIf (subconfig'.mode == "isolated") (writeTextDir dropInFile ''
          [Service]
          BindReadOnlyPaths=${configDir}/resolv.conf:/etc/resolv.conf
        '')))];

      systemd.services = {
        "systemd-network-isolation@" = {
          description = "Network Isolation Helper";
          bindsTo = ["systemd-network-isolation-bridge.service"];
          after = ["systemd-network-isolation-bridge.service"];
          unitConfig.StopWhenUnneeded = true;
          serviceConfig.Type = "oneshot";
          serviceConfig.RemainAfterExit = true;
          path = [pkgs.iproute2];
          script = ''
            service="$(systemd-escape "$(systemd-escape -u --instance "$(systemctl whoami)")")"
            ns="$service.service"
            source ${configDir}/config
            source ${configDir}/service-configs/"$service.conf"
            peer="srv+$(printf "%x" $$ | head -c11)"
            dev="''${dev:-''${peer/+/-}}"
            ip netns delete "$ns" 2> /dev/null || :
            set -x
            ip netns add "$ns"
            ip -n "$ns" link set up dev lo
            ip link add "$dev" type veth peer name "$peer"
            ip link set "$dev" up master "$master"
            ip link set "$peer" up master "$master"
            ip link set "$peer" netns "$ns"
            ip -n "$ns" link set "$peer" name gateway up
            for addr in "''${addrs[@]}"; do
              ip -n "$ns" -4 address add dev gateway "$addr/$cidr" broadcast +
            done
            for addr6 in "''${addrs6[@]}"; do
              ip -n "$ns" -6 address add dev gateway "$addr6/$cidr6"
            done
            ip -n "$ns" -4 route add default via "$gateway" dev gateway
            ip -n "$ns" -6 route add default via "$gateway6" dev gateway
          '';
          serviceConfig.ExecStopPost = ["-ip netns delete %i.service"];
        };
        systemd-network-isolation-bridge = {
          description = "Network Isolation Bridge";
          serviceConfig.Type = "oneshot";
          serviceConfig.RemainAfterExit = true;
          path = [pkgs.iproute2];
          script = ''
            ${readFile "${configDir}/config"}
            set -x
            ip link delete "$master" 2> /dev/null || :
            ip link add "$master" type bridge stp_state 0
            ip -4 address add dev "$master" "$gateway/$cidr" broadcast +
            ip -6 address add dev "$master" "$gateway6/$cidr6"
            ip link set dev "$master" up
          '';
          serviceConfig.ExecStopPost = ["-ip -echo link delete ${config'.ifName}"];
        };
        systemd-network-isolation-dns = {
          description = "Network Isolation DNS Forwarder";
          partOf = ["systemd-network-isolation-bridge.service"];
          wantedBy = ["systemd-network-isolation-bridge.service"];
          after = ["systemd-network-isolation-bridge.service"];
          unitConfig.StopWhenUnneeded = true;
          serviceConfig = {
            Type = "forking";
            GuessMainPID = true;
            ExecStart = "${getExe pkgs.aardvark-dns} -p 53 -c /tmp run";
            PrivatePIDs = false;
            PrivateUsers = false;
            CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE"];
            AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
            SocketBindDeny = "any";
            SocketBindAllow = "53";
            BindReadOnlyPaths =
              let config = readFile "${configDir}/aardvark-dns-config";
              in ["${writeText "config" config}:/tmp/config"];
            SystemCallFilter = [
              "@basic-io" "@file-system" "@sync" "@io-event"
              "@network-io" "@signal" "@process" "pipe2"
            ];
          };
          hardening' = {
            enable = true;
            filesystem.packages = [pkgs.aardvark-dns];
            network.mode = "host";
          };
        };
      };
      networking.firewall' = {
        rpFilter.rules = ''
          ip saddr ${config'.ipv4.subnet} iifname != ${config'.ifName} drop
          ip6 saddr ${config'.ipv6.subnet} iifname != ${config'.ifName} drop
        '';
        ingress.rules = ''
          iifname ${config'.ifName} meta l4proto {tcp, udp} th dport 53 accept
        '';
        egress.rules = ''
          ip daddr ${config'.ipv4.subnet} oifname != ${config'.ifName} drop
          ip6 daddr ${config'.ipv6.subnet} oifname != ${config'.ifName} drop
        '';
        forward.rules = "iifname ${config'.ifName} jump accept-if-internet";
        snat.rules = "iifname ${config'.ifName} masquerade";
      };
      # Prevent intranetwork communication.
      networking.nftables.tables.systemd-network-isolation = {
        family = "bridge";
        content = ''
          chain forward {
            type filter hook forward priority filter
            ip daddr ${config'.ipv4.subnet} drop
            ip6 daddr ${config'.ipv6.subnet} drop
          }
        '';
      };
    };
}
