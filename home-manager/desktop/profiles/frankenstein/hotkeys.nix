{lib, pkgs, systemConfig, config, ...}:
let inherit (lib) mkIf mkDefault mkForce elem catAttrs mkMerge;
    inherit (pkgs) writeScript;
    isInstalled = pkg: (elem pkg (catAttrs "pname" config.home.packages));
in mkIf config.desktop'.profile.frankenstein.enable {
  services.sxhkd' = {
    enable = mkDefault true;
    keybindings = mkMerge [
      {
        #"super + q" = ''
        #  ${pkgs.systemd}/bin/systemctl --user restart home-activation
        #'';
        # HACK: suppress middle-click-paste
        "~button2" = ";${pkgs.xsel}/bin/xsel -npc";
      }
      (mkIf (isInstalled "xfce4-whiskermenu-plugin") {
        "super + F1" = ''
          ${pkgs.xfce4-whiskermenu-plugin}/bin/xfce4-popup-whiskermenu
        '';
      })
      (mkIf (config.i18n.inputMethod.type == "fcitx5") {
        "super + space" = ''
          ${pkgs.fcitx5}/bin/fcitx5-remote -t
        '';
      })
      (mkIf systemConfig.services.pipewire.wireplumber.enable {
        "XF86AudioMute" = ''
          ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        '';
        "XF86AudioLowerVolume" = ''
          ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        '';
        "XF86AudioRaiseVolume" = ''
          ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
        '';
      })
      {
        "Print" = ''
          ${pkgs.maim}/bin/maim -f png \
            | ${pkgs.xclip}/bin/xclip -quiet -selection clipboard -t image/png
        '';
      }
    ];
  };
  services.xcape = {
    enable = mkDefault true;
    mapExpression = {
      "Super_L" = mkDefault "Super_L|F1";
      "Super_R" = mkDefault "Super_L|F1";
    };
  };
}
