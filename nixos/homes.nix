{config, lib, pkgs, nixfiles, ...}:
let inherit (lib) mkMerge forEach filter attrValues strings catAttrs pipe;
    inherit (strings) escapeShellArg escapeNixString;
    eligibleUsers = pipe (attrValues config.users.users) [
      (filter (user: user.isNormalUser && user.createHome))
      (catAttrs "name")
    ];
    currentSystem = pkgs.stdenv.hostPlatform.system;
    home-manager = nixfiles.inputs.home-manager.packages.${currentSystem}.default;
in {
  systemd.tmpfiles.settings.homes = mkMerge (forEach eligibleUsers (user: {
    "${config.system.usersDirectory'}/${user}".d = {
      inherit user;
      inherit (config.users.users.${user}) group;
      mode = "0700";
    };
  }));
  systemd.user.services.home-activation = {
    description = "Home Activation for %u";
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = "yes";
    wantedBy = ["nixos-activation.service"];
    partOf = ["nixos-activation.service"];
    after = ["nixos-activation.service"];
    before = ["default.target"];
    unitConfig.ConditionUser = strings.join "|" eligibleUsers;
    serviceConfig.SyslogIdentifier = "home-activation";
    script = ''
      nix_quote() {
        nix-instantiate --eval --expr "{x}: x" --argstr x "$*"
      }
      write_if_missing() {
        local path="$1"; shift
        [ -e "$path" ] && return
        cat > "$path"
      }

      users_dir=${escapeShellArg config.system.usersDirectory'}
      config_dir="$users_dir/$USER/config"

      mkdir -p "$config_dir"
      write_if_missing "$config_dir/flake.nix" <<-EOF
				{
				  inputs.system.url = "path:/run/current-system-config";
				  outputs = {self, system, ...}: system.lib.mkHome self;
				}
			EOF
      write_if_missing "$config_dir/default.nix" <<-EOF
				{
				  home.username = $(nix_quote "$USER");
				  home.stateVersion = ${escapeNixString config.system.nixos.release};
				}
			EOF

      nix flake update --offline --flake "$config_dir"
      home-manager switch --flake "$config_dir"
      # HACK: reloadSystemd is skipped during service manager startup
      if [ "$(systemctl --user is-system-running)" = "starting" ]; then
        systemctl --user daemon-reload
      fi
    '';
    path = with pkgs; [coreutils nix home-manager systemd];
  };
}
