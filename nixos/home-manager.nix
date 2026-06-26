{config, lib, lib', pkgs, nixfiles, ...}:
let inherit (lib) mkIf filterAttrs mkOption concatMapAttrs pipe strings;
    inherit (pkgs) writeScript writeText;
    inherit (strings) escapeShellArg escapeNixString;
    inherit (lib') escapeSystemd;
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
      (concatMapAttrs (user: {group, home, homeMode, homeManager', ...}: {
        "home-manager-for-${escapeSystemd user}" = {
          description = "Home Manager for ${user}";
          wantedBy = ["multi-user.target"];
          wants = ["nix-daemon.socket"];
          after = ["nix-daemon.socket"];
          before = ["systemd-user-sessions.service"];
          serviceConfig.Type = "oneshot";
          serviceConfig.RemainAfterExit = true;
          serviceConfig.User = user;
          serviceConfig.Group = group;
          unitConfig.RequiresMountsFor = [home "/data/per-user/${user}"];
          serviceConfig.SyslogIdentifier = "home-manager-for-${escapeSystemd user}";
          serviceConfig.ExecStartPre = "+" + writeScript "make-user-dir" ''
            #!${pkgs.runtimeShell} -e

            user_dir=${escapeShellArg "/data/per-user/${user}"}
            mkdir -vp -m0700 "$user_dir"
            chown -v ${escapeShellArg user}:${escapeShellArg group} "$user_dir"
          '';
          serviceConfig.ExecStart = writeScript "initialize" ''
            #!${pkgs.runtimeShell} -e

            user_dir=${escapeShellArg "/data/per-user/${user}"}
            if ((${toString homeManager'.generateConfig})) &&
               ! [ -d "$user_dir/config" ]; then
              mkdir -vp "$user_dir/config"
              cp -v --update=none ${writeText "flake.nix" ''
                {
                  inputs.system.url = "path:/run/current-system-config";
                  outputs = {self, system, ...}: system.lib.mkHome self {
                    home.username = ${escapeNixString user};
                    home.stateVersion = ${escapeNixString config.system.nixos.release};
                  };
                }
              ''} "$user_dir/config/flake.nix"
              cp -v --update=none <(echo "{}") "$user_dir/config/default.nix"
            fi

            activation_script="$user_dir/state/activate"
            [ -f "$activation_script" ] || exit 0
            # run the activation script from a login shell
            set -- ${pkgs.runtimeShell} -elc 'exec "$@"' "" \
                   "$activation_script" \
                   --driver-version 1
            export XDG_RUNTIME_DIR="/run/user/$UID"
            systemd-run --user --quiet --collect --pipe \
                        --service-type=oneshot \
                        --expand-environment=no \
                        --ignore-failure \
              "$@" ||
            "$@" || :
          '';
        };
      }))
    ];
  };
}
