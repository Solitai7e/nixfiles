{config, lib, ...}:
let stateDir = "${config.system.stateDirectory'}/openssh";
    inherit (lib) mkDefault;
in {
  services.openssh.settings = {
    PasswordAuthentication = mkDefault false;
    KbdInteractiveAuthentication = mkDefault false;
  };
  services.openssh.hostKeys = mkDefault [{
    path = "${stateDir}/ssh_host_rsa_key";
    type = "rsa";
    bits = 4096;
  } {
    path = "${stateDir}/ssh_host_ed25519_key";
    type = "ed25519";
  }];
}
