{lib, pkgs, config, ...}:
let inherit (lib) mkIf mkDefault range pipe concatMapAttrs;
    inherit (config.lib.file) mkOutOfStoreSymlink;
    inherit (pkgs) runCommand runCommandWith symlinkJoin;
    xfce4-whiskermenu-open-helper = (runCommandWith {
      name = "xfce4-whiskermenu-open-helper";
      derivationArgs = {
        buildInputs = with pkgs; [vala glib libnotify];
        nativeBuildInputs = with pkgs; [pkg-config];
      };
    } ''
      valac --cc="$CC" \
            --pkg=gtk+-3.0 \
            --pkg=libnotify \
            --output="$out" \
        ${./xfce4-whiskermenu-open-helper.vala}
    '');
in mkIf config.desktop'.profile.frankenstein.enable {
  home.packages = with pkgs; [
    xfce4-whiskermenu-plugin
    xfce4-pulseaudio-plugin
    xfce4-clipman-plugin
    xfce4-notifyd
  ];
  systemd.user.services.xfce4-panel = {
    Unit.PartOf = ["graphical-session.target"];
    Unit.After = ["graphical-session.target"];
    Install.WantedBy = ["graphical-session.target"];
    Service.ExecStart = ["${pkgs.xfce4-panel}/bin/xfce4-panel --sm-client-disable -d"];
  };
  xfconf.settings.xfce4-panel = {
    "panels" = [1];
    "panels/dark-mode" = mkDefault (config.gtk.colorScheme == "dark");

    "panels/panel-1/mode" = 0;
    "panels/panel-1/size" = 30;
    "panels/panel-1/position" = "p=8;x=0;y=1000000";
    "panels/panel-1/position-locked" = true;
    "panels/panel-1/background-alpha" = 95;
    "panels/panel-1/background-rgba" = [0.12 0.12 0.12 0.9];
    "panels/panel-1/background-style" = 0;
    "panels/panel-1/enable-struts" = true;
    "panels/panel-1/icon-size" = 0;
    "panels/panel-1/length" = 100;
    "panels/panel-1/length-adjust" = true;
    "panels/panel-1/plugin-ids" = range 1 18;

    "plugins/plugin-1" = "whiskermenu";
    "plugins/plugin-1/button-icon" = "${./org.xfce.panel.whiskermenu.svg}";
    "plugins/plugin-1/hover-switch-category" = false;
    "plugins/plugin-1/position-categories-alternate" = true;
    "plugins/plugin-1/recent-items-max" = 0;
    "plugins/plugin-1/menu-height" = 500;
    "plugins/plugin-1/menu-width" = 400;
    "plugins/plugin-1/show-command-hibernate" = false;
    "plugins/plugin-1/command-hibernate" = "${pkgs.systemd}/bin/systemctl hibernate";
    "plugins/plugin-1/show-command-lockscreen" = true;
    "plugins/plugin-1/command-lockscreen" = "${pkgs.xset}/bin/xset s activate";
    "plugins/plugin-1/show-command-logoutuser" = true;
    "plugins/plugin-1/command-logoutuser"= "${pkgs.systemd}/bin/systemctl --user stop graphical-session.target";
    "plugins/plugin-1/show-command-restart" = true;
    "plugins/plugin-1/command-restart" = "${pkgs.systemd}/bin/reboot";
    "plugins/plugin-1/show-command-shutdown" = true;
    "plugins/plugin-1/command-shutdown" = "${pkgs.systemd}/bin/shutdown now";
    "plugins/plugin-1/show-command-suspend" = false;
    "plugins/plugin-1/show-command-menueditor" = false;
    "plugins/plugin-1/show-command-profile" = false;
    "plugins/plugin-1/show-command-settings" = false;
    "plugins/plugin-1/show-command-logout" = false;
    "plugins/plugin-1/search-actions" = 2;
    "plugins/plugin-1/search-actions/action-0/command" = "${xfce4-whiskermenu-open-helper} /%u";
    "plugins/plugin-1/search-actions/action-0/name" = "Open";
    "plugins/plugin-1/search-actions/action-0/pattern" = "/";
    "plugins/plugin-1/search-actions/action-0/regex" = false;
    "plugins/plugin-1/search-actions/action-1/command" = "${xfce4-whiskermenu-open-helper} \\0";
    "plugins/plugin-1/search-actions/action-1/name" = "Open URI";
    "plugins/plugin-1/search-actions/action-1/pattern" = "^[a-z0-9+.-]+://[^\s]+$";
    "plugins/plugin-1/search-actions/action-1/regex" = true;
    "plugins/plugin-1/favorites" = [
      "cudatext.desktop"
      "aseprite.desktop"
      "org.keepassxc.KeePassXC.desktop"
      "org.strawberrymusicplayer.strawberry.desktop"
      "ca.desrt.dconf-editor.desktop"
    ];

    "plugins/plugin-2" = "separator";
    "plugins/plugin-2/style" = 0;

    "plugins/plugin-3" = "launcher";
    "plugins/plugin-3/items" = ["launcher-3.desktop"];

    "plugins/plugin-4" = "launcher";
    "plugins/plugin-4/items" = ["launcher-4.desktop"];

    "plugins/plugin-5" = "launcher";
    "plugins/plugin-5/items" = ["launcher-5.desktop"];

    "plugins/plugin-6" = "launcher";
    "plugins/plugin-6/items" = ["launcher-6.desktop"];

    "plugins/plugin-7" = "launcher";
    "plugins/plugin-7/items" = ["launcher-7.desktop"];

    "plugins/plugin-8" = "separator";
    "plugins/plugin-8/style" = 0;

    "plugins/plugin-9" = "pager";
    "plugins/plugin-9/miniature-view" = true;

    "plugins/plugin-10" = "windowmenu";
    "plugins/plugin-10/all-workspaces" = true;
    "plugins/plugin-10/style" = 1;
    "plugins/plugin-10/workspace-actions" = false;
    "plugins/plugin-10/workspace-names" = true;

    "plugins/plugin-11" = "tasklist";
    "plugins/plugin-11/flat-buttons" = false;
    "plugins/plugin-11/grouping" = false;
    "plugins/plugin-11/include-all-monitors" = false;
    "plugins/plugin-11/middle-click" = 1;
    "plugins/plugin-11/show-handle" = false;
    "plugins/plugin-11/show-labels" = true;
    "plugins/plugin-11/sort-order" = 4;

    "plugins/plugin-12" = "separator";
    "plugins/plugin-12/expand" = true;
    "plugins/plugin-12/style" = 0;

    "plugins/plugin-13" = "systray";
    "plugins/plugin-13/icon-size" = 22;
    "plugins/plugin-13/menu-is-primary" = false;

    "plugins/plugin-14" = "notification-plugin";

    "plugins/plugin-15" = "xfce4-clipman-plugin";
    "plugins/clipman/settings/add-primary-clipboard" = false;
    "plugins/clipman/tweaks/inhibit" = false;
    "plugins/clipman/tweaks/never-confirm-history-clear" = true;
    "plugins/clipman/tweaks/save-on-quit" = false;

    "plugins/plugin-16" = "pulseaudio";
    "plugins/plugin-16/enable-keyboard-shortcuts" = false;
    "plugins/plugin-16/enable-multimedia-keys" = true;
    "plugins/plugin-16/show-notifications" = true;

    "plugins/plugin-17" = "clock";
    "plugins/plugin-17/digital-layout" = 3;
    "plugins/plugin-17/digital-time-font" = "Sans Bold 10";
    "plugins/plugin-17/digital-time-format" = "%I:%M %p";
    "plugins/plugin-17/tooltip-format" = "%A, %B %d, %Y";

    "plugins/plugin-18" = "showdesktop";
  };
  gtk.gtk3.extraCss = ''
    .xfce4-panel .toggle image {
      -gtk-icon-transform: scale(0.8);
    }
  '';

  xdg.configFile =
    let launchers = {
          "3" = "chromium-browser.desktop";
          "4" = "nemo.desktop";
          "5" = "org.gnome.Terminal.desktop";
          "6" = "org.gnome.SystemMonitor.desktop";
          "7" = "xfce4-screenshooter.desktop";
        };
    in pipe launchers [(concatMapAttrs (i: entry: {
      "xfce4/panel/launcher-${i}/launcher-${i}.desktop".source =
        mkOutOfStoreSymlink "${config.home.profileDirectory}/share/applications/${entry}";
    }))];

  # there has to be a better way...
  nixpkgs.overlays = [(final: prev: {
    xfce4-whiskermenu-plugin = symlinkJoin {
      inherit (prev.xfce4-whiskermenu-plugin) pname version;
      paths = [prev.xfce4-whiskermenu-plugin];
      postBuild = ''
        mkdir -p "$out/share/icons/hicolor/symbolic/apps"
        ln -sfn ${./org.xfce.panel.whiskermenu.svg} \
                "$out/share/icons/hicolor/symbolic/apps/org.xfce.panel.whiskermenu.svg"

        mkdir -p "$out/libexec"
        mv "$out/bin/xfce4-popup-whiskermenu" "$out/libexec/.xfce4-popup-whiskermenu"
        cat <<-EOF > "$out/bin/xfce4-popup-whiskermenu"
          $out/libexec/.xfce4-popup-whiskermenu "$@"
					${final.coreutils}/bin/sleep 0.1
					${final.wmctrl}/bin/wmctrl -a "Whisker Menu" -F
				EOF
				chmod +x "$out/bin/xfce4-popup-whiskermenu"
      '';
    };
  })];
}
