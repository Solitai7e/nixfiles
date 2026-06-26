{config, lib, ...}:
let inherit (lib) mkDefault;
    inherit (lib.generators) mkLuaInline;
in {
  wayland.windowManager.hyprland = {
    settings.config = {
      general.layout = mkDefault "master";
      misc.disable_hyprland_logo = mkDefault true;
      misc.middle_click_paste = mkDefault false;
    };
    extraConfig = ''
      hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), {mouse = true})
      hl.bind("SUPER + mouse:273", hl.dsp.window.drag(), {mouse = true})
    '';
  };
  programs.waybar = {
    enable = mkDefault config.wayland.windowManager.hyprland.enable;
    systemd.enable = mkDefault true;
    settings.main = {
      layer = "top";
      position = "top";
      height = 30;
      modules-left = ["hyprland/workspaces"];
      modules-right = [];
      "hyprland/workspaces" = {};
    };
  };
}
