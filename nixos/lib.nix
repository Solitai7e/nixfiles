{lib, pkgs, ...}:
let inherit (lib) mkOption; in {
  options.lib' = with lib.types; mkOption {
    description = "Private utility functions.";
    type = attrsOf anything;
    default = {};
  };
}
