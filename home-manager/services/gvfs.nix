{
  nixpkgs.overlays = [(final: prev: {
    gvfs = prev.gvfs.overrideAttrs {
      mesonFlags = prev.mesonFlags or [] ++ [
        "-Dafc=false"
        "-Dgphoto2=false"
        "-Dgcr=false"
        "-Dgoa=false"
        "-Donedrive=false"
        "-Dkeyring=false"
      ];
    };
  })];
}
