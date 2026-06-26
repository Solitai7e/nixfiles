{lib, pkgs, config, ...}:
let inherit (lib) mkIf;
    inherit (config.lib.file) mkOutOfStoreSymlink;
in mkIf config.programs.home-manager.enable {
  xdg.configFile."home-manager/flake.nix".source =
    mkOutOfStoreSymlink "${config.home.configDirectory'}/flake.nix";
}
