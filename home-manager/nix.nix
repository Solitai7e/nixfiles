{lib, systemConfig, ...}:
let inherit (lib) mkDefault mkIf; in {
  nix.assumeXdg = mkIf (
    systemConfig.nix.enable &&
    systemConfig.nix.settings.use-xdg-base-directories)
      (mkDefault true);
}
