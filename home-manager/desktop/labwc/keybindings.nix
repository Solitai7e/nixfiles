{pkgs, lib, config, ...}:
let inherit (lib) mkIf attrValues forEach optionalString getAttr;
    config' = config.wayland.windowManager.labwc;
in mkIf config'.enable {
  wayland.windowManager.labwc.rc.keyboard.keybind =
    forEach (attrValues config.desktop'.keybindings) (binding: {
      "@key" =
        optionalString binding.hotkey.ctrl "C-" +
        optionalString binding.hotkey.meta "A-" +
        optionalString binding.hotkey.shift "S-" +
        optionalString binding.hotkey.super "W-" +
        optionalString binding.hotkey.hyper "H-" +
        binding.hotkey.key;
      "@onRelease" = if binding.triggerOn == "release" then "yes" else "no";
      action =
        if binding.command != null then {
          "@name" = "Execute";
          "@command" = binding.command;
        } else getAttr binding.action {
          "close" = { "@name" = "Close"; };
          "minimize" = { "@name" = "Iconify"; };
          "toggle-maximized" = { "@name" = "ToggleMaximize"; };
          "toggle-fullscreen" = { "@name" = "ToggleFullscreen"; };
          "toggle-always-on-top" = { "@name" = "ToggleAlwaysOnTop";};
          "toggle-sticky" = { "@name" = "ToggleOmnipresent"; };
          "cycle" = { "@name" = "NextWindow"; };
        };
    });
}
