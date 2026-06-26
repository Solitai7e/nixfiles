{lib, pkgs, config, ...}:
let inherit (lib) hiPrio mkIf mkOverride getAttr;
    inherit (pkgs) symlinkJoin;
    package = hiPrio (symlinkJoin {
      inherit (pkgs.materia-theme) pname version;
      paths = [pkgs.materia-theme];
      postBuild = ''
        find -L "$out/share/themes" -mindepth 1 -maxdepth 1 \
             -type d -exec ln -sfnT ${./openbox-3} {}/openbox-3 \;
        find -L "$out/share/themes" -mindepth 1 -maxdepth 3 \
             -type f -name gtk.css \
             ! -execdir test -e gtk-dark.css \; \
             -execdir ln -sfn gtk.css gtk-dark.css \;
      '';
    });
    variant = if config.gtk.colorScheme != "dark" then "light" else "dark";
in mkIf (config.desktop'.enable && config.desktop'.theme == "materia") {
  gtk = {
    theme = {
      name = mkOverride 900 (getAttr variant {
        light = "Materia-compact";
        dark = "Materia-dark-compact";
      });
      package = mkOverride 900 package;
    };
    iconTheme = {
      name = mkOverride 900 (getAttr variant {
        light = "Papirus";
        dark = "Papirus-Dark";
      });
      package = mkOverride 900 pkgs.papirus-icon-theme;
    };
  };
  qt.kvantum = {
    themes = [pkgs.materia-kde-theme];
    settings.General.theme = mkOverride 900 (getAttr variant {
      light = "MateriaLight";
      dark = "MateriaDark";
    });
  };
  wayland.windowManager.labwc.rc.theme = {
    cornerRadius = mkOverride 900 4;
    font = mkOverride 900 [
      { "@place" = "ActiveWindow"; weight = "bold"; }
      { "@place" = "InactiveWindow"; weight = "bold"; }
    ];
  };
  desktop'.background = mkOverride 900 { "*".image = ./wallpaper.jpg; };
}
