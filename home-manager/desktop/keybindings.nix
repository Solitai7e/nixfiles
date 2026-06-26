{lib, lib', ...}:
let inherit (builtins) isNull;
    inherit (lib) mkOption match head filter const mapAttrs setAttrByPath;
    inherit (lib') mkPipe neg apply;
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
      elemType = coercedTo lines (setAttrByPath ["command"]) (submodule ({name, ...}: {
        options = {
          hotkey = mkOption {
            type = anything;
            default = mkHotkey name;
            readOnly = true;
            visible = false;
          };
          command = mkOption {
            description = "Execute one or more commands.";
            type = nullOr lines;
            default = null;
          };
          action = mkOption {
            description = "Perform a special action.";
            type = nullOr str;
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
  config.desktop'.keybindings = {
    "<Super_L>" = {
      command = "xfce4-popup-whiskermenu";
      triggerOn = "release";
    };
    "s-<Tab>" = { action = "cycle"; };
    "M-<F4>" = { action = "close"; };
  };
}
