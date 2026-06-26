{lib, ...}:
let inherit (lib) mkOption mkDefault; in {
  options.desktop'.theme = with lib.types; mkOption {
    description = "TODO";
    type = str;
  };
  config.desktop'.theme = mkDefault "materia";
}
