{lib, pkgs, ...}:
let inherit (lib) mkOption mkIf;
    inherit (pkgs) symlinkJoin writeClosure;
in {
  options.systemd.services = with lib.types; mkOption {
    type = attrsOf (submodule (args: let subconfig = args.config; in {
      options.hardening'.filesystem = mkOption {
        type = submodule {
          freeformType = attrsOf anything;
          options = {
            mode = mkOption {
              description = "Filesystem isolation mode for the service.";
              type = enum ["host" "chroot"];
              default = "chroot";
            };
            packages = mkOption {
              description = "Packages to copy to the service's chroot.";
              type = listOf (either path package);
              default = [];
            };
            paths = mkOption {
              description = ''
                Packages to create links for in the service's
                chroot. Implicitly added to packages.
              '';
              type = listOf (either path package);
              default = [];
            };
          };
        };
      };
      config =
        let subconfig' = subconfig.hardening'.filesystem;
            derivationArgs = removeAttrs subconfig' ["mode" "packages"];
        in {
          hardening'.filesystem.packages = subconfig'.paths;
          serviceConfig = mkIf (
            subconfig.hardening'.enable &&
            subconfig'.mode == "chroot"
          ) {
            RootEphemeral = true;
            RootDirectory = symlinkJoin (derivationArgs // {
              name = "${subconfig.name}-chroot";
              postBuild = ''
                mkdir -p "$out"
                xargs -r -d "\n" -- cp -vR -t "$out" --parents \
                      < ${writeClosure subconfig'.packages}
                mkdir -p "$out/var"
                ln -sfn ../run "$out/var/run"
                ${derivationArgs.postBuild or ""}
              '';
            });
            InaccessiblePaths = ["+/sys"];
          };
        };
    }));
  };
}
