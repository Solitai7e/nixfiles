{lib, pkgs, config, ...}:
let inherit (lib) mkDefault mkOption mkIf hiPrio forEach toJSON strings
                  escapeShellArg mapAttrsToList mergeAttrsList pipe;
    inherit (pkgs) runCommand symlinkJoin;
    config' = config.programs.cudatext;
    writeLexer = src: runCommand "cudatext-lexer" {} ''
      src=${escapeShellArg "${src}"}
      dest="$out/share/cudatext"
      find "$src" -mindepth 1 -maxdepth 1 \
           \( -name "*.lcf" -o -name "*.cuda-lexmap" \) \
           -exec mkdir -p "$dest/data/lexlib" \; \
           -exec ln -snfv -t "$dest/data/lexlib" {} + -o \
           -name "*.cuda-litelexer" \
           -exec mkdir -p "$dest/data/lexliblite" \; \
           -exec ln -snfv -t "$dest/data/lexliblite" {} + -o \
           -name "*.acp" \
           -exec mkdir -p "$dest/data/autocomplete" \; \
           -exec ln -snfv -t "$dest/data/autocomplete" {} + -o \
           -name "lexer *.json" \
           -exec mkdir -p "$dest/settings_default" \; \
           -exec ln -snfv -t "$dest/settings_default" {} +
    '';
    writePlugin = src: runCommand "cudatext-plugin" {} ''
      src=${escapeShellArg "${src}"}
      dest="$out/share/cudatext"
      subdir="$(awk -F '[= ]' '$1 == "subdir" { print $2; }' "$src/install.inf")"
      test -n "$subdir"
      mkdir -p "$dest/py"
      ln -sfn "$src" "$dest/py/$subdir"
    '';
in {
  options.programs.cudatext = with lib.types; {
    lexers' = mkOption {
      description = "List of lexers to install.";
      type = listOf path;
      default = [];
    };
    plugins' = mkOption {
      description = "List of plugins to install.";
      type = listOf path;
      default = [];
    };
    pythonPackage' = mkOption {
      description = "The Python package to use.";
      type = package;
      default = pkgs.python3;
    };
    finalPackage' = mkOption {
      description = ''
        The resulting CudaText package with all
        of our customizations applied.
      '';
      type = package;
      default = hiPrio (symlinkJoin {
        inherit (config'.package) pname version;
        paths =
          [config'.package] ++
          (map writeLexer config'.lexers') ++
          (map writePlugin config'.plugins');
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
					site_packages=${escapeShellArg (strings.join "/" [
    			  config'.pythonPackage'
    			  config'.pythonPackage'.sitePackages
    			])}
          wrapProgram "$out/bin/cudatext" \
                      --prefix NIX_PYTHONPATH : "$site_packages"
        '';
      });
      readOnly = true;
    };
    pluginSettings' = mkOption {
      description = "Custom plugin-specific config files.";
      type = attrsOf json;
      default = {};
    };
  };

  config = mkIf config'.enable {
    xdg.configFile =
      let configSkeleton = forEach ["data" "py" "settings_default"] (dir: {
            "cudatext/${dir}".source =
              "${config'.finalPackage'}/share/cudatext/${dir}";
          });
          pluginConfigs = pipe config'.pluginSettings' [(mapAttrsToList (name: value: {
            "cudatext/settings/${name}.json".text = toJSON value;
          }))];
      in mergeAttrsList (configSkeleton ++ pluginConfigs);

    home.packages = [config'.finalPackage'];

    programs.cudatext.userSettings.pylib__linux =
      mkDefault "${config'.pythonPackage'}/lib/libpython3.so";

    programs.cudatext = {
      userSettings = {
        font_name__linux = mkDefault "Monospace";
        font_size__linux = mkDefault 11;
        ui_font_size__linux = mkDefault 10;
        ui_theme = mkDefault "ebony";
        ui_theme_syntax = mkDefault "ebony";
        ui_buffered__linux = mkDefault false;
        renderer_tweaks__linux = mkDefault "";
        ui_reopen_session = mkDefault false;
        ui_reopen_session_cmdline = mkDefault false;
        ui_auto_save_session = mkDefault false;
        ui_sidepanel_on_start = mkDefault 2;
        ui_bottom_on_start = mkDefault 2;
        minimap_show = mkDefault true;
        tab_size = mkDefault 2;
        tab_spaces = mkDefault true;
        saving_trim_spaces = mkDefault true;
        saving_trim_final_empty = mkDefault true;
        saving_force_final_eol = mkDefault true;
        ui_links_confirm = mkDefault false;
        show_last_line_on_top = mkDefault true;
        ui_max_size_lexer = mkDefault 5;
      };
      lexerSettings = {
        "Python".tab_size = mkDefault 2;
      };
      hotkeys = {
        "2533" = {
          name = "ui: toggle side panel";
          s1 = ["F2"];
        };
        "2534" = {
          name = "ui: toggle bottom panel";
          s1 = ["F3"];
        };
        "2590" = {
          name = "find next";
          s1 = [];
        };
        "2621" = {
          name = ''split tab: toggle "horizontally"/"vertically"'';
          s1 = [];
        };
        "302" = {
          name = "toggle word-wrap mode (off / on)";
          s1 = ["F4"];
        };
        "240" = {
          name = "indent selection";
          s1 = ["Alt+Tab"];
        };
        "cuda_lsp,call_hover" = {
          name = "plugin: LSP Client: Hover";
          s1 = ["Alt+Q"];
        };
      };
    };
  };
}
