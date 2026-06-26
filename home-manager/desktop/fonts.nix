{lib, pkgs, config, ...}:
let inherit (lib) mkIf mkDefault;
in mkIf (config.desktop'.profileName != null) {
  home.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    hack-font
  ];
  fonts.fontconfig = {
    enable = true;
    antialiasing = true;
    defaultFonts = {
      serif = mkDefault ["Noto Serif"];
      sansSerif = mkDefault ["Noto Sans"];
      monospace = mkDefault ["Hack"];
      emoji = mkDefault ["Noto Color Emoji"];
    };
  };
}
