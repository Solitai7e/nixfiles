{nixfiles, config, lib, pkgs, ...}:
let inherit (lib) mkIf mkDefault mkBefore mkAfter getExe;
    currentSystem = pkgs.stdenv.hostPlatform.system;
in mkIf config.desktop'.enable {
  programs.waybar = {
    enable = mkDefault true;
    package = mkDefault nixfiles.inputs.waybar.packages.${currentSystem}.waybar;
    systemd.enable = mkDefault true;
    settings.primary = {
      layer = mkDefault "top";
      position = mkDefault "bottom";
      height = mkDefault 30;
      spacing = mkDefault 6;
      modules-left = mkBefore ["ext/workspaces" "wlr/taskbar"];
      modules-right = mkAfter ["tray" "privacy" "wireplumber" "clock"];
      "ext/workspaces" = {
        format = mkDefault " {id} ";
        on-click = mkDefault "activate";
      };
      "wlr/taskbar" = {
        format = mkDefault "{icon} {title}";
        on-click = mkDefault "minimize-raise";
        on-click-middle = mkDefault "close";
        homogeneous = mkDefault true;
        truncate = mkDefault true;
        bar-css-states = mkDefault true;
      };
      "privacy" = {
        modules = [
          { type = "audio-in"; }
          { type = "audio-out"; }
          { type = "screenshare"; }
          { type = "location"; }
        ];
      };
      "wireplumber" = {
        format = mkDefault "{icon}";
        format-muted = mkDefault "";
        format-icons = mkDefault ["" "" ""];
        tooltip-format = mkDefault "<b>Volume {volume}%</b>\n<small>{node_name}</small>";
        scroll-step = mkDefault 5.0;
        on-click = mkDefault (getExe pkgs.pavucontrol);
        on-click-middle = mkDefault "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      };
      "clock" = {
        format = mkDefault "<b>{:%I:%M %p}</b>";
        tooltip-format = mkDefault "{:%A, %B %d, %Y}";
      };
    };
    style = ''

    '';
    #systemd.enableInspect = true;
  };
}
