{lib, pkgs, config, ...}:
let inherit (lib) hiPrio mkIf mkOverride;
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
        find "$out/share/themes" -mindepth 1 -maxdepth 2 \
             -type d -name metacity-1 \
          | while read -r path; do
            find -L "$path" -mindepth 1 -maxdepth 1 \
                 -type f -name "metacity-theme-*.xml" \
                 -exec cp -L {} {}.new \; \
                 -exec mv -f {}.new {} \;
            patch -d "$path" -p2 < ${./metacity.patch}
          done
      '';
    });
in mkIf (config.desktop'.enable && config.desktop'.theme == "materia") {
  gtk.theme.package = mkOverride 900 package;
  gtk.theme.name = mkOverride 900 (
    if config.gtk.colorScheme != "dark"
      then "Materia-compact"
      else "Materia-dark-compact");
  gtk.iconTheme.package = mkOverride 900 pkgs.papirus-icon-theme;
  gtk.iconTheme.name = mkOverride 900 (
    if config.gtk.colorScheme != "dark"
      then "Papirus"
      else "Papirus-Dark");
  qt.style.name = mkOverride 900 "kvantum";
  qt.kvantum = {
    enable = mkOverride 900 true;
    themes = [pkgs.materia-kde-theme];
    settings.General.theme = mkOverride 900 (
    if config.gtk.colorScheme != "dark"
      then "MateriaLight"
      else "MateriaDark");
  };
  desktop'.background = mkOverride 900 { "*".image = ./wallpaper.jpg; };
  wayland.windowManager.labwc.rc.theme.cornerRadius = mkOverride 900 4;
}
