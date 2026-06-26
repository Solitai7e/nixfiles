{self, lib, ...}:
let inherit (lib) mkDefault; in {
  fileSystems."/nix" = {
    device = "/data/state/nix";
    fsType = "none";
    options = ["bind"];
    neededForBoot = true;
  };
  fileSystems."/var/lib/nixos" = {
    device = "/data/state/nixos";
    fsType = "none";
    options = ["bind"];
    neededForBoot = true;
  };

  nix.settings = {
    allowed-users = ["@users"];
    experimental-features = ["nix-command" "flakes"];
    auto-optimise-store = mkDefault true;
    use-xdg-base-directories = mkDefault true;
  };
  nix.channel.enable = mkDefault false;

  environment.etc."nixos/flake.nix" = {
    source = "/data/config/flake.nix";
    mode = "symlink";
  };
  system.activationScripts.current-config = ''
    # HACK: this should be a symlink but that causes nix to
    #       think the input is impure for some reason
    mkdir -p /run/current-system-config
    umount -q /run/current-system-config || :
    mount -o bind ${self.outPath} /run/current-system-config
  '';
}
