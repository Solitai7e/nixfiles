{lib, pkgs, config, ...}:
let inherit (lib) mkIf mkEnableOption getExe;
    inherit (pkgs) makeDesktopItem writeShellApplication;
in {
  options.programs.syslogFeed = {
    enable = mkEnableOption "the syslog feed program";
  };
  config = mkIf config.programs.syslogFeed.enable {
    home.packages = [(makeDesktopItem {
      name = "syslog-feed";
      desktopName = "Syslog Feed";
      comment = "A Live Feed of the System Logs";
      icon = "log-viewer-app";
      exec = getExe (writeShellApplication {
        name = "syslog-feed";
        runtimeInputs = with pkgs; [polkit systemd];
        text = ''
          printf "\\e]0;Syslog Feed\\007"
          exec pkexec journalctl -f
        '';
      });
      terminal = true;
      categories = ["System"];
    })];
  };
}
