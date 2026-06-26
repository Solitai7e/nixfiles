{lib, pkgs, config, ...}:
let inherit (lib) mkIf mkDefault; in
mkIf config.desktop'.profile.frankenstein.enable {
  systemd.user.services.marco = {
    Unit.PartOf = ["graphical-session.target"];
    Unit.After = ["graphical-session.target"];
    Install.WantedBy = ["graphical-session.target"];
    Service.ExecStart = ["${pkgs.marco}/bin/marco --sm-disable --replace"];
  };
  dconf.settings = {
    "org/mate/desktop/interface" = {
      enable-animations = mkDefault false;
    };
    "org/mate/marco/general" = {
      action-middle-click-titlebar = mkDefault "none";
      compositing-manager = mkDefault true;
      mouse-button-modifier = mkDefault "<Super>";
      num-workspaces = mkDefault 4;
      theme = mkDefault "Yaru-dark";
      focus-new-windows = mkDefault "smart";
    };
    "org/mate/marco/global-keybindings" = {
      cycle-group = mkDefault "disabled";
      cycle-panels = mkDefault "disabled";
      cycle-windows = mkDefault "disabled";
      panel-main-menu = mkDefault "disabled";
      panel-run-dialog = mkDefault "disabled";
      run-command-screenshot = mkDefault "disabled";
      run-command-window-screenshot = mkDefault "disabled";
      show-desktop = mkDefault "disabled";
      switch-group = mkDefault "disabled";
      switch-panels = mkDefault "disabled";
      switch-to-workspace-down = mkDefault "disabled";
      switch-to-workspace-left = mkDefault "disabled";
      switch-to-workspace-right = mkDefault "disabled";
      switch-to-workspace-up = mkDefault "disabled";
      switch-windows = mkDefault "<Super>Tab";
    };
    "org/mate/marco/window-keybindings" = {
      activate-window-menu = mkDefault "disabled";
      begin-move = mkDefault "disabled";
      begin-resize = mkDefault "disabled";
      minimize = mkDefault "disabled";
      move-to-workspace-down = mkDefault "disabled";
      move-to-workspace-left = mkDefault "disabled";
      move-to-workspace-right = mkDefault "disabled";
      move-to-workspace-up = mkDefault "disabled";
      toggle-above = mkDefault "<Super>D";
      toggle-maximized = mkDefault "disabled";
      toggle-on-all-workspaces = mkDefault "<Super>F";
      unmaximize = mkDefault "disabled";
    };
  };
}
