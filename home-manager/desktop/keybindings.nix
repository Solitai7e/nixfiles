{config, lib, lib', pkgs, ...}:
let config' = config.desktop'.keybindings;
    inherit (builtins) isNull;
    inherit (lib) mkOption match filter getExe forEach
                  mkDefault mapAttrs attrValues const
                  head optionalString setAttrByPath;
    inherit (lib') mkPipe neg apply;
    inherit (pkgs) writeShellApplication writeShellScript;
    mkHotkey = mkPipe [
      (match "(C-)?(M-)?(s-)?(H-)?([^ <>]|(S-)?<([^<> ]+)>)")
      (apply (ctrl: meta: super: hyper: key: shift: namedKey:
        (mapAttrs (const (neg isNull)) {
          inherit ctrl meta super hyper shift;
        }) // {
          key = head (filter (neg isNull) [namedKey key]);
        }))
    ];
in {
  options.desktop'.keybindings = with lib.types; mkOption {
    description = "Global keyboard shortcuts.";
    type = attrsWith {
      placeholder = "hotkey";
      elemType = coercedTo lines (setAttrByPath ["execute"]) (submodule ({name, ...}: {
        options = {
          hotkey = mkOption {
            type = anything;
            default = mkHotkey name;
            readOnly = true;
            visible = false;
          };
          execute = mkOption {
            description = "Execute one or more commands.";
            type = nullOr lines;
            default = null;
          };
          triggerOn = mkOption {
            description = "When the keybinding should be triggered.";
            type = enum ["pressed" "release"];
            default = "pressed";
          };
        };
      }));
    };
    default = {};
  };
  config = {
    desktop'.keybindings = {
      "<Print>" = mkDefault (getExe (writeShellApplication {
        name = "printscreen";
        runtimeInputs = with pkgs; [grim wl-clipboard];
        text = "grim - | wl-copy -t image/png";
      }));
    };
    wayland.windowManager.labwc.rc.keyboard.keybind =
      forEach (attrValues config') ({hotkey, triggerOn, execute, ...}: {
        "@key" = with hotkey;
          optionalString ctrl "C-" +
          optionalString meta "A-" +
          optionalString shift "S-" +
          optionalString super "W-" +
          optionalString hyper "H-" +
          key;
        "@onRelease" = if triggerOn == "release" then "yes" else "no";
        action = {
          "@name" = "Execute";
          "@command" = writeShellScript "keybinding" execute;
        };
      }) ++ [
        { "@key" = "W-Tab";  action."@name" = "NextWindow"; }
        { "@key" = "W-f";    action."@name" = "ToggleAlwaysOnTop"; }
        { "@key" = "W-d";    action."@name" = "ToggleOmnipresent"; }
        { "@key" = "A-<F4>"; action."@name" = "Close"; }
      ];
  };
}
