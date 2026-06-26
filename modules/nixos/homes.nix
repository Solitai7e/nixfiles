{config, lib, pkgs, ...}:
let inherit (lib) pipe mkMerge mkIf forEach filter attrValues
                  toString match head version;
    eligibleUsers = filter (user: user.isNormalUser && user.createHome)
                           (attrValues config.users.users);
in {
  systemd.tmpfiles.settings.homes = mkMerge (forEach eligibleUsers (user: {
    "/data/user/${user.name}"."d" = {
      user = user.name;
      group = user.group;
      mode = "0700";
    };
    "/data/user/${user.name}/configuration"."d" = {
      user = user.name;
      group = user.group;
    };
    "/data/user/${user.name}/state"."d" = {
      user = user.name;
      group = user.group;
    };
    "/data/user/${user.name}/personal"."d" = {
      user = user.name;
      group = user.group;
    };
  }));
  environment =
    let nixosVersion = head (match "([0-9]+\.[0-9]+).*" version);
        provision-home-manager = pkgs.writeScriptBin "provision-home-manager" ''
          #!/usr/bin/env nix-shell
          #! nix-shell -i bash -p nix
          set -e

          nix_quote() {
            nix-instantiate --eval --expr "{x}: x" --argstr x "$*"
          }

          config_dir="/data/user/$USER/configuration"
          [ -d "$config_dir" ] || exit 0

          if ! [ -f "$config_dir/flake.nix" ]; then
            cat <<-EOF > "$config_dir/flake.nix"
							{
							  inputs = {
							    nixpkgs.url = "github:NixOS/nixpkgs/nixos-${nixosVersion}";
							    home-manager = {
							      url = "github:nix-community/home-manager/release-${nixosVersion}";
							      inputs.nixpkgs.follows = "nixpkgs";
							    };
							    nixfiles.url = {
							      url = "github:Solitai7e/nixfiles";
							      inputs.nixpkgs.follows = "nixpkgs";
							    };
							  };
							  outputs = inputs@{nixpkgs, home-manager, nixfiles, ...}: {
							    homeConfigurations.$(nix_quote "$USER") = home-manager.lib.homeManagerConfiguration {
							      pkgs = nixpkgs.legacyPackages.x86_64-linux;
							      modules = builtins.attrValues nixfiles.homeManagerModules ++ [{
							        home.username = $(nix_quote "$USER");
							        home.stateVersion = "${nixosVersion}";
							        imports = [./home.nix];
							      }];
							    };
							  };
							}
						EOF
          fi
          if ! [ -f "$config_dir/home.nix" ]; then
            echo -E "{}" > "$config_dir/home.nix"
          fi
          if ! [ -d ~/.local/state/home-manager ]; then
            echo "Provisioning Home Manager..." >&2
            nix run home-manager/release-${nixosVersion} -- init --switch "$config_dir"
          fi
      '';
    in {
      systemPackages = [provision-home-manager];
      extraInit = "${provision-home-manager}/bin/provision-home-manager";
    };
}
