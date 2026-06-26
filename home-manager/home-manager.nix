{lib, config, ...}:
let inherit (lib) mkDefault;
    inherit (config.lib.file) mkOutOfStoreSymlink;
in {
  programs.home-manager.enable = mkDefault true;

  xdg.configFile."home-manager/flake.nix".source =
    mkOutOfStoreSymlink "${config.home.configDirectory'}/flake.nix";
}
