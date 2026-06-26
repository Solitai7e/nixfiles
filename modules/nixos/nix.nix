{config, lib, ...}:
let inherit (lib) mkDefault; in {
  environment.etc."nixos/flake.nix" = {
    source = "/data/configuration/flake.nix";
    mode = "symlink";
  };
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nix.channel.enable = mkDefault false;
}
