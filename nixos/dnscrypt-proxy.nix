{lib, pkgs, config, ...}:
let inherit (lib) mkOption mkEnableOption mkPackageOption getExe
                  mkDefault pipe mkIf filter strings;
    inherit (pkgs.writers) writeTOML;
    config' = config.services.dnscrypt-proxy';
    stateDir = "${config.system.stateDirectory'}/dnscrypt-proxy";
in {
  options.services.dnscrypt-proxy' = with lib.types; {
    enable = mkEnableOption "dnscrypt-proxy";
    package = mkPackageOption pkgs "dnscrypt-proxy" {};
    settings = mkOption {
      description = "dnscrypt-proxy configuration.";
      type = submodule { freeformType = (pkgs.formats.toml {}).type; };
      default = {};
    };
  };
  config = mkIf config'.enable {
    networking.nameservers = mkDefault (pipe config'.settings.listen_addresses [
      (filter (strings.hasSuffix ":53"))
      (map (strings.removeSuffix ":53"))
    ]);
    services.dnscrypt-proxy'.settings = {
      listen_addresses = mkDefault ["127.0.0.1:53"];

      server_names = [];
      require_nolog = mkDefault true;
      require_nofilter = mkDefault true;

      query_log.file = mkDefault "/var/lib/dnscrypt-proxy/query.log";
      nx_log.file = mkDefault "/var/lib/dnscrypt-proxy/nx.log";

      sources.public-resolvers = mkDefault {
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        cache_file = "/var/lib/dnscrypt-proxy/sources/public-resolvers.md";
        refresh_delay = 72;
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
      };
    };
    systemd.services.dnscrypt-proxy =
      let configFile = writeTOML "dnscrypt-proxy.toml" config'.settings; in {
        description = "dnscrypt-proxy Client";
        wants = ["network-online.target" "nss-lookup.target"];
        before = ["nss-lookup.target"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "exec";
          ExecStart = "${getExe config'.package} -config ${configFile}";
          PrivateNetwork = false;
          PrivateUsers = false;
          DynamicUser = false;
          User = "dnscrypt-proxy";
          Group = "dnscrypt-proxy";
          CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE"];
          AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
          SocketBindDeny = "any";
          SocketBindAllow = "53";
          BindPaths = ["${stateDir}:/var/lib/dnscrypt-proxy"];
        };
        hardening' = {
          enable = true;
          rootFs.inputs = [config'.package configFile];
        };
      };
    users.users.dnscrypt-proxy = {
      isSystemUser = true;
      group = "dnscrypt-proxy";
      home = stateDir;
    };
    users.groups.dnscrypt-proxy = {};
  };
}
