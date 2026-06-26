{config, lib, ...}:
let inherit (lib) mkDefault; in {
  networking.hostName = mkDefault config.system.name;
  i18n.defaultLocale = mkDefault "en_US.UTF-8";
  time.timeZone = mkDefault "Etc/UTC";

  users.mutableUsers = mkDefault false;
  security.sudo.extraConfig = "Defaults lecture = never";

  systemd.oomd.enable = mkDefault false;
  services.logrotate.enable = mkDefault false;
  networking.nftables.enable = mkDefault true;
  services.pipewire.pulse.enable = mkDefault config.services.pipewire.enable;

  programs.nano.enable = mkDefault false;
}
