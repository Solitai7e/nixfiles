{
  fileSystems."/var/log/journal" = {
    device = "/data/state/journal";
    fsType = "none";
    options = ["bind"];
    neededForBoot = true;
  };
}
