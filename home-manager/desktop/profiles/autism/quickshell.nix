{config, lib, ...}:
let inherit (lib) mkIf mkDefault toString;
    inherit (config.lib.file) mkOutOfStoreSymlink;
in mkIf config.desktop'.profile.autism.enable {
  programs.quickshell = {
    enable = mkDefault true;
    systemd.enable = mkDefault true;
  };
  xdg.configFile = mkIf config.programs.quickshell.enable {
    #"quickshell".source = mkOutOfStoreSymlink "${config.home.configDirectory'}/quickshell";
  };
}
