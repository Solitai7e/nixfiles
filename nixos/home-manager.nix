{config, lib, utils, pkgs, nixfiles, ...}:
let inherit (lib) mkIf filterAttrs mkOption concatMapAttrs pipe strings;
    inherit (pkgs) writeScript writeText;
    inherit (strings) escapeShellArg escapeNixString;
    inherit (utils) escapeSystemdPath;
    currentSystem = pkgs.stdenv.hostPlatform.system;
    home-manager = nixfiles.inputs.home-manager.packages.${currentSystem}.default;
in {
  options = with lib.types; {
    users.users = mkOption {
      type = attrsOf (submodule (args:
        let subconfig = args.config;
            subconfig' = subconfig.homeManager';
        in {
          options.homeManager' = {
            enable = mkOption {
              description = "Whether to enable Home Manager for the user.";
              type = bool;
              default = subconfig.isNormalUser && subconfig.createHome;
            };
            generateConfig = mkOption {
              description = ''
                Whether to automatically generate a pre-populated config
                directory for the user if one isn't already present.
              '';
              type = bool;
              default = true;
            };
          };
          config = {
            packages = mkIf subconfig'.enable [home-manager];
          };
        }));
    };
  };
  config = {
    systemd.services = pipe config.users.users [
      (filterAttrs (user: settings: settings.homeManager'.enable))
      (concatMapAttrs (user: {group, home, homeMode, homeManager', ...}:
        let inherit (homeManager') generateConfig;
            userDir = "${config.system.usersDirectory'}/${user}";
            unit = "home-manager-for-${escapeSystemdPath user}";
        in {
          ${unit} = {
            description = "Home Manager for ${user}";
            wantedBy = ["multi-user.target"];
            wants = ["nix-daemon.socket"];
            after = ["nix-daemon.socket"];
            before = ["systemd-user-sessions.service"];
            serviceConfig.Type = "oneshot";
            serviceConfig.RemainAfterExit = true;
            serviceConfig.User = user;
            serviceConfig.Group = group;
            unitConfig.RequiresMountsFor = home;
            serviceConfig.SyslogIdentifier = unit;
            serviceConfig.ExecStartPre = "+" + writeScript "make-user-dir" ''
              #!${pkgs.runtimeShell} -e
              user_dir=${escapeShellArg userDir}
              mkdir -vp -m ${homeMode} "$user_dir"
              chown -v ${escapeShellArg user}:${escapeShellArg group} "$user_dir"
            '';
            serviceConfig.ExecStart = writeScript "initialize" ''
              #!${pkgs.runtimeShell} -e

              config_dir=${escapeShellArg "${userDir}/config"}
              if ((${toString generateConfig})) && ! [ -d "$config_dir" ]; then
                mkdir -vp "$config_dir"
                cp -v --update=none ${writeText "flake.nix" ''
                  {
                    inputs.system.url = "path:/run/current-system-config";
                    outputs = {self, system, ...}: system.lib.mkHome self;
                  }
                ''} "$config_dir/flake.nix"
                cp -v --update=none ${writeText "default.nix" ''
                  {
                    home.username = ${escapeNixString user};
                    home.stateVersion = ${escapeNixString config.system.nixos.release};
                  }
                ''} "$config_dir/default.nix"
              fi

              # run the activation script from a login shell
              activate=${writeScript "activate" ''
                #!${pkgs.runtimeShell} -el
                script=${escapeShellArg "${userDir}/state/activate"}
                [ -f "$script" ] || exit 0
                exec "$script" --driver-version 1
              ''}
              export XDG_RUNTIME_DIR="/run/user/$(id -u)"
              systemd-run --user --quiet --collect --pipe \
                          --service-type=oneshot \
                          --expand-environment=no \
                          --ignore-failure \
                "$activate" ||
              "$activate" || :
            '';
          };
        }))
    ];
  };
}
