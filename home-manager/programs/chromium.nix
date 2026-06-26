{lib, pkgs, config, options, ...}:
let inherit (lib) mkDefault mkOption mkMerge mkOverride strings mkIf;
    config' = config.programs.chromium;
    options' = options.programs.chromium;
in {
  options.programs.chromium = with lib.types; {
    defaultBrowser' = mkOption {
      description = "Whether to configure Chromium as the default web browser.";
      type = bool;
      default = false;
    };
  };
  config = mkMerge [
    (mkIf config'.defaultBrowser' (
      let mkSamePriority = mkOverride options'.defaultBrowser'.highestPrio; in {
        home.sessionVariables = {
          "BROWSER" = mkSamePriority "${config'.finalPackage}/bin/chromium";
        };
        xdg.mimeApps.defaultApplications = {
          "x-scheme-handler/http" = mkSamePriority "chromium.desktop";
          "x-scheme-handler/https" = mkSamePriority "chromium.desktop";
        };
    }))
    {
      programs.chromium = {
        package = mkDefault pkgs.ungoogled-chromium;
        commandLineArgs = [
          "--user-data-dir=${config.home.stateDirectory'}/chromium"
          "--ignore-gpu-blocklist"
          ("--enable-features=" + strings.join "," [
            "Vulkan"
            "DefaultANGLEVulkan"
            "VulkanFromANGLE"
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
    }
  ];
}
