{lib, pkgs, config, ...}:
let inherit (lib) mkDefault strings; in {
  programs.chromium = {
    package = mkDefault pkgs.ungoogled-chromium;
    commandLineArgs = mkDefault [
      "--user-data-dir=/data/user/${config.home.username}/state/chromium"
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
