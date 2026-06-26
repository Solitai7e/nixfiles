{lib, config, pkgs, ...}:
let inherit (lib) mkIf mkOption mkDefault filterAttrs
                  attrNames findFirst pipe;
in {
  options.desktop' = with lib.types; {
    profileName = mkOption {
      description = "Name of the enabled desktop configuration.";
      type = nullOr str;
      default = pipe config.desktop'.profile [
        (filterAttrs (name: profile: profile.enable))
        attrNames
        (findFirst (_: true) null)
      ];
      readOnly = true;
      visible = false;
    };
  };
  config = mkIf (config.desktop'.profileName != null) {
    home.packages = with pkgs; [gvfs];
    programs.chromium.enable = mkDefault true;
    programs.chromium.defaultBrowser' = mkDefault true;
  };
}
