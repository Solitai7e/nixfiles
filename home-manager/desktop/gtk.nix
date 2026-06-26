{lib, pkgs, config, ...}:
let inherit (lib) mkIf mkDefault mkOverride split filter
                  isString strings pipe escapeURL;
    toFileUri = path: pipe path [
      (split "/+")
      (filter (item: isString item && item != ""))
      (map escapeURL)
      (strings.join "/")
      (path: "file:///${path}")
    ];
in {
  gtk.enable = mkDefault (config.desktop'.profileName != null);
  gtk.iconTheme.package = mkDefault config.gtk.theme.package;
  gtk.iconTheme.name = mkDefault config.gtk.theme.name;
  gtk.colorScheme = mkDefault "dark";
  home.sessionVariables.ADW_DISABLE_PORTAL = mkDefault "1";

  gtk.gtk3.bookmarks =
    let configDir = config.home.configDirectory';
        xdgUserDirs = map (name: config.xdg.userDirs.${name}) [
          "projects" "documents" "music"
          "pictures" "videos" "download"
        ];
    in [("${toFileUri configDir} Configuration")] ++
       map toFileUri xdgUserDirs;
}
