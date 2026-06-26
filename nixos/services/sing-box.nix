{lib, pkgs, config, ...}:
let inherit (lib) mkOption mkEnableOption mkDefault mkPackageOption mkIf getExe;
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
        after = ["network-online.target"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "exec";
          ExecStart = "${getExe config'.package} -c ${configFile} run";
          RestrictAddressFamilies = ["AF_NETLINK"];
          SystemCallFilter = [
            "@basic-io" "@file-system" "@sync" "@io-event"
            "@network-io" "@signal" "@process" "pipe2"
          ];
        };
        hardening' = {
          enable = true;
          filesystem.packages = [config'.package configFile];
          network = {
            mode = "isolated";
            ifName = "sing-box";
            addresses = ["10.80.0.5" "fddd:14f1:d4b5:7248::5"];
          };
        };
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
