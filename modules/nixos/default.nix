{config, lib, ...}:
let inherit (lib) mkDefault; in {
  networking.hostName = mkDefault config.system.name;
  i18n.defaultLocale = mkDefault "en_US.UTF-8";
  time.timeZone = mkDefault "Etc/UTC";

  systemd.oomd.enable = mkDefault false;
  programs.nano.enable = mkDefault false;
  networking.nftables.enable = mkDefault true;
  services.pipewire.pulse.enable = mkDefault config.services.pipewire.enable;
}
