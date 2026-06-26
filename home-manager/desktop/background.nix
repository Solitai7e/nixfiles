{config, lib, lib', pkgs, ...}:
let config' = config.desktop'.background;
    inherit (lib) mkOption mkIf pipe getAttr length
                  escapeShellArg escapeShellArgs imap0
                  getExe concatMapAttrs optionals;
    inherit (lib') escapeSystemd;
    inherit (pkgs) linkFarm writeShellScript;
    writeWallpaperScript = output: {transform, path}:
      writeShellScript "wallpaper-${output}" (escapeShellArgs (
        ["exec" (getExe config.services.awww.package) "img" path] ++
        optionals (output != "*") ["--outputs" output] ++
        ["--resize" (getAttr transform {
          zoom = "no";
          stretch = "stretch";
          crop = "crop";
        })]));
in {
  options.desktop'.background = with lib.types; mkOption {
    description = ''
      Per-output desktop background settings.
      The special value "*" can be used to
      apply the settings to every output.
    '';
    type = attrsWith {
      placeholder = "output";
      elemType = attrTag rec {
        image = mkOption {
          description = "Display a single image.";
          type = coercedTo path (path: { inherit path; }) (submodule {
            options = {
              path = mkOption {
                description = "Path to the image file.";
                type = path;
              };
              transform = mkOption {
                description = "Apply a transformation to the image.";
                type = enum ["zoom" "stretch" "crop" "fit"];
                default = "crop";
              };
            };
          });
        };
        slideshow = mkOption {
          description = "Display a slideshow of images.";
          type = submodule {
            options = {
              interval = mkOption {
                description = ''
                  How long to wait between each background change.
                  See {manpage}`systemd.time(7)` for the exact format.
                '';
                type = coercedTo int toString str;
                default = "1m";
              };
              images = mkOption {
                description = "Images to include in the slideshow.";
                type = nonEmptyListOf image.type;
              };
              random = mkOption {
                description = ''
                  Whether to pick a random image everytime instead
                  of simply cycling through the list in order.
                '';
                type = bool;
                default = false;
              };
            };
          };
        };
      };
    };
    default = {};
  };
  config = mkIf (config' != {}) {
    services.awww.enable = true;
    systemd.user = pipe config' [(concatMapAttrs (output:
      let suffix = if output == "*" then "" else "-${escapeSystemd output}";
      in concatMapAttrs (type: getAttr type {
        image = image: {
          services."wallpaper${suffix}" = {
            Unit = {
              Description = "Desktop Wallpaper on ${output}";
              PartOf = ["graphical-session.target"];
              Requires = ["awww.service"];
              After = ["graphical-session.target" "awww.service"];
            };
            Service = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = writeWallpaperScript output image;
              Slice = "session.slice";
            };
            Install.WantedBy = ["graphical-session.target"];
          };
        };
        slideshow = {images, interval, random}: {
          services."slideshow${suffix}" = {
            Unit = {
              Description = "Desktop Slideshow on ${output}";
              Requires = ["awww.service"];
              After = ["awww.service"];
            };
            Service = {
              Type = "oneshot";
              ExecStart = writeShellScript "slideshow" ''
                output=${escapeShellArg output}
                scripts=${linkFarm "slideshow" (pipe images [(imap0 (i: image: {
                  name = "${toString i}.sh";
                  path = writeWallpaperScript output image;
                }))])}
                n_scripts=${toString (length images)}
                ${if random then ''
                  i="$(shuf -n 1 -i 0-$((n_scripts - 1)))"
                ''
                else ''
                  counter="$XDG_RUNTIME_DIR/slideshow/$output"
                  i=$(($(cat "$counter" 2> /dev/null || echo 0) % n_scripts))
                  trap 'echo $((i + 1)) > "$counter"' EXIT
                ''}
                "$scripts/$i.sh"
              '';
              Slice = "session.slice";
              RuntimeDirectory = mkIf (!random) "slideshow";
              RuntimeDirectoryPreserve = mkIf (!random) true;
            };
          };
          timers."slideshow${suffix}" = {
            Unit = {
              Description = "Desktop Slideshow on %i";
              PartOf = ["graphical-session.target"];
              After = ["graphical-session.target"];
            };
            Timer = {
              OnBootSec = "0";
              OnUnitActiveSec = interval;
            };
            Install.WantedBy = ["graphical-session.target"];
          };
        };
      })
    ))];
  };
}
