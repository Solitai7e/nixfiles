{lib, pkgs, ...}:
let inherit (lib) mkDefault; in {
  services.openssh.settings = {
    PasswordAuthentication = mkDefault false;
    KbdInteractiveAuthentication = mkDefault false;
  };
  services.openssh.hostKeys = mkDefault [{
    bits = 4096;
    path = "/data/state/ssh/ssh_host_rsa_key";
    type = "rsa";
  } {
    path = "/data/state/ssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];
}
