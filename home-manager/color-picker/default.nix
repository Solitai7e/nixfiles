{lib, pkgs, config, ...}:
let inherit (lib) mkIf mkEnableOption;
    inherit (pkgs) stdenv;
in {
  options.programs.colorPicker' = {
    enable = mkEnableOption "Color Picker";
  };
  config = mkIf config.programs.colorPicker'.enable {
    home.packages = [(stdenv.mkDerivation {
      pname = "color-picker";
      version = "0.0";
      src = ./.;
      nativeBuildInputs = with pkgs.qt6; [qmake wrapQtAppsHook];
      buildInputs = with pkgs.qt6; [qtbase qtwayland];
    })];
  };
}
