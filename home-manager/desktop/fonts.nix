{lib, pkgs, config, ...}:
let inherit (lib) mkIf mkDefault;
in mkIf config.desktop'.enable {
  home.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    hack-font
  ];
  fonts.fontconfig = {
    enable = mkDefault true;
    antialiasing = mkDefault true;
    defaultFonts = {
      serif = ["Noto Serif"];
      sansSerif = ["Noto Sans"];
      monospace = ["Hack"];
      emoji = ["Noto Color Emoji"];
    };
  };
}
