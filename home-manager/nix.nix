{lib, config, systemConfig, ...}:
let inherit (lib) mkDefault mkIf escapeShellArg; in {
  nix.assumeXdg = mkIf (
    systemConfig.nix.enable &&
    systemConfig.nix.settings.use-xdg-base-directories)
      (mkDefault true);

  home.activation = with lib.hm.dag; {
    linkActivationScript = entryAfter ["writeBoundary"] ''
      run ln -sfnT $VERBOSE_ARG \
             "$(readlink -f "$BASH_SOURCE")" \
             ${escapeShellArg config.home.dataDirectory'}/state/activate
    '';
  };
}
