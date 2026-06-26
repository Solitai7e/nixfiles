{lib, pkgs, config, ...}:
let inherit (lib) mkIf mkOrder mkDefault;
in mkIf config.desktop'.enable {
  home.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    hack-font
    font-awesome
  ];
  fonts.fontconfig = {
    enable = mkDefault true;
    antialiasing = mkDefault true;
    defaultFonts = {
      serif = mkOrder 1200 ["Noto Serif"];
      sansSerif = mkOrder 1200 ["Noto Sans"];
      monospace = mkOrder 1200 ["Hack"];
      emoji = mkOrder 1200 ["Noto Color Emoji"];
    };
  };
}
