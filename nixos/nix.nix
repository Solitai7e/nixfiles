{self, config, lib, ...}:
let inherit (lib) mkDefault mkOption; in {
  config = {
    fileSystems."/nix" = {
      device = "${config.system.stateDirectory'}/nix";
      fsType = "none";
      options = ["bind"];
      neededForBoot = true;
    };
    fileSystems."/var/lib/nixos" = {
      device = "${config.system.stateDirectory'}/nixos";
      fsType = "none";
      options = ["bind"];
      neededForBoot = true;
    };

    environment.etc."nixos/flake.nix" = {
      source = "${config.system.configDirectory'}/flake.nix";
      mode = "symlink";
    };
    system.activationScripts.current-config = ''
      # HACK: this should be a symlink but that causes nix to
      #       think the input is impure for some reason
      mkdir -p /run/current-system-config
      umount -q /run/current-system-config || :
      mount -o bind ${self.outPath} /run/current-system-config
    '';

    nix.settings = {
      allowed-users = ["@users"];
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = mkDefault true;
    };
    nix.channel.enable = mkDefault false;
  };
}
