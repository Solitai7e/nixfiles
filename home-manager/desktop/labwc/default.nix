{pkgs, lib, lib', config, ...}:
let inherit (lib) mkIf mkDefault getExe toString pipe mkMerge flip range;
    inherit (lib') getAttrs' escapeShellVars;
    config' = config.wayland.windowManager.labwc;
in mkMerge [
  { wayland.windowManager.labwc.enable = mkDefault config.desktop'.enable; }
  (mkIf config'.enable {
    wayland.windowManager.labwc = {
      rc = {
        desktops.names.name = mkDefault (map (i: "   ${toString i}   ") (range 1 4));
        theme.name = mkDefault config.gtk.theme.name;
        theme.icon = mkDefault config.gtk.iconTheme.name;
        theme.dropShadows = mkDefault "yes";
      };
      environment = pipe ["XCURSOR_PATH" "XCURSOR_THEME" "XCURSOR_SIZE"] [
        (flip getAttrs' config.systemd.user.sessionVariables)
        escapeShellVars
      ];
      systemd.enable = false;
      autostart = ["${pkgs.systemd}/bin/systemd-notify --ready"];
    };
    xdg.configFile."labwc/shutdown".text = ''
      ${pkgs.systemd}/bin/systemd-notify --stopping
    '';
    systemd.user.services.wayland-compositor.Service = {
      Type = "notify";
      NotifyAccess = "all";
      ExecStart = getExe config'.package;
      ExecReload = "${getExe config'.package} -r";
    };
  })
]
