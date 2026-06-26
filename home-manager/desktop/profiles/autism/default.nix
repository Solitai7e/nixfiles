{lib, pkgs, config, ...}:
let inherit (lib) mkIf mkForce mkEnableOption;
in {
  options.desktop'.profile.autism = {
    enable = mkEnableOption ''the desktop configuration "Autism"'';
  };
}
