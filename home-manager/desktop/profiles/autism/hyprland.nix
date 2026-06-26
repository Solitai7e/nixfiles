{config, lib, ...}:
let inherit (lib) mkIf mkDefault;
in mkIf config.desktop'.profile.autism.enable {
  wayland.windowManager.hyprland = {
    enable = mkDefault true;
    settings.config = {
      general.layout = mkDefault "master";
      general.snap.enabled = mkDefault true;
      misc.disable_hyprland_logo = mkDefault true;
      misc.middle_click_paste = mkDefault false;
    };
    extraConfig = ''
      hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), {mouse = true})
      hl.bind("SUPER + mouse:273", hl.dsp.window.drag(), {mouse = true})
    '';
  };
}
