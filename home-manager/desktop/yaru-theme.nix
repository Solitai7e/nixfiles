{
  nixpkgs.overlays = [(final: prev: {
    yaru-theme = prev.yaru-theme.overrideAttrs (final: prev: {
      patches = (prev.patches or []) ++ [./yaru-theme.patch];
    });
  })];
}
