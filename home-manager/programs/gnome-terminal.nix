{lib, config, ...}:
let config' = config.programs.gnome-terminal;
    inherit (lib) mkIf mkDefault;
    profileId = "00000000-0000-0000-0000-000000000000";
in {
  programs.gnome-terminal = {
    profile.${profileId} = {
      visibleName = mkDefault "Default";
      default = mkDefault true;
      font = mkDefault "Monospace 11";
      allowBold = mkDefault true;
      boldIsBright = mkDefault true;
      scrollOnOutput = mkDefault false;
    };
  };
  dconf.settings = with lib.hm.gvariant; mkIf config'.enable {
    "org/gnome/terminal/legacy" = {
      headerbar = mkDefault (mkJust true);
    };
    "org/gnome/terminal/legacy/profiles:/:${profileId}" = {
      # HACK: boldIsRight is ignored when colors == null, home-manager bug
      bold-is-bright = mkDefault config'.profile.${profileId}.boldIsBright;
    };
  };
}
