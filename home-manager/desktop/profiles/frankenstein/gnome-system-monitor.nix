{lib, pkgs, config, ...}:
let inherit (lib) mkIf mkDefault;
in mkIf config.desktop'.profile.frankenstein.enable {
  home.packages = with pkgs; [gnome-system-monitor];
  dconf.settings = {
    "org/gnome/gnome-system-monitor" = {
      cpu-smooth-graph = false;
      current-tab = "processes";
      maximized = true;
      network-total-in-bits = false;
      process-memory-in-iec = true;
      resources-disk-expanded = true;
      resources-memory-in-iec = true;
      resources-net-expanded = true;
      show-all-fs = false;
      show-dependencies = false;
      show-whose-processes = "all";
    };
    "org/gnome/gnome-system-monitor/disksview" = {
      col-device-width = 322;
      col-directory-width = 655;
      col-type-width = 84;
      sort-col = "device";
      sort-order = 0;
    };
    "org/gnome/gnome-system-monitor/proctree" = {
      col-0-visible = true;
      col-0-width = 791;
      col-1-visible = true;
      col-1-width = 133;
      col-8-visible = true;
      col-8-width = 66;
      col-9-visible = false;
      col-9-width = 80;
      col-10-visible = false;
      col-10-width = 70;
      col-11-visible = true;
      col-11-width = 48;
      col-12-visible = true;
      col-12-width = 69;
      col-14-visible = false;
      col-14-width = 120;
      col-15-visible = true;
      col-15-width = 78;
      col-22-visible = true;
      col-22-width = 117;
      col-23-visible = true;
      col-23-width = 120;
      col-24-visible = true;
      col-24-width = 87;
      col-25-visible = true;
      col-25-width = 91;
      col-26-visible = false;
      col-26-width = 0;
      columns-order = [12 1 0 2 3 4 6 9 10 8 13 14 15 16 17 18 19 20 21 24 25 22 23 11 26 7];
      sort-col = 8;
      sort-order = 0;
    };
  };
}
