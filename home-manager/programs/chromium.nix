{lib, pkgs, config, options, ...}:
let config' = config.programs.chromium;
    options' = options.programs.chromium;
    inherit (lib) mkDefault mkOption mkOverride strings mkIf hiPrio;
    inherit (pkgs) symlinkJoin;
    mkBrowserDefault = mkOverride options'.defaultBrowser'.highestPrio;
in {
  options.programs.chromium = with lib.types; {
    defaultBrowser' = mkOption {
      description = "Whether to configure Chromium as the default web browser.";
      type = bool;
      default = false;
    };
  };
  config = mkIf config'.defaultBrowser' {
    programs.chromium = {
      package = mkDefault pkgs.ungoogled-chromium;
      commandLineArgs = [
        "--user-data-dir=${config.home.dataDirectory'}/state/chromium"
        "--ignore-gpu-blocklist"
        ("--enable-features=" + strings.join "," [
          "CanvasOopRasterization"
          "AcceleratedVideoEncoder"
          "AcceleratedVideoDecoder"
          "VaapiIgnoreDriverChecks"
        ])
        "--start-maximized"
        "--show-avatar-button=incognito-and-guest"
        "--disable-search-engine-collection"
        "--no-default-browser-check"
        "--extension-mime-request-handling=always-prompt-for-install"
        "--load-media-router-component-extension=0"
        "--webrtc-ip-handling-policy=default_public_interface_only"
        "--disable-top-sites"
        "--bookmark-bar-ntp=never"
      ];
    };
    home.packages = [(hiPrio (symlinkJoin {
      inherit (config'.package) pname version;
      paths = [config'.finalPackage];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram "$out/bin/chromium" \
          --suffix GIO_EXTRA_MODULES : ${pkgs.dconf.lib}/lib/gio/modules
      '';
    }))];
    systemd.user.sessionVariables."BROWSER" =
      mkBrowserDefault "${config'.finalPackage}/bin/chromium";
    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/http" = mkBrowserDefault "chromium.desktop";
      "x-scheme-handler/https" = mkBrowserDefault "chromium.desktop";
    };
  };
}
