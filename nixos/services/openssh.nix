{lib, ...}:
let inherit (lib) mkDefault; in {
  services.openssh.settings = {
    PasswordAuthentication = mkDefault false;
    KbdInteractiveAuthentication = mkDefault false;
  };
  services.openssh.hostKeys = mkDefault [{
    path = "/data/state/openssh/ssh_host_rsa_key";
    type = "rsa";
    bits = 4096;
  } {
    path = "/data/state/openssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];
}
