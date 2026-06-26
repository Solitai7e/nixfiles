{lib, pkgs, config, ...}:
let inherit (lib) mkIf mkEnableOption mkPackageOption mkOption
                  escapeShellArgs optionalString;
    inherit (pkgs) symlinkJoin;
    config' = config.services.gvfs';
in {
  options.services.gvfs' = with lib.types; {
    enable = mkEnableOption "the GNOME Virtual Filesystem daemon";
    mountables = mkOption {
      description = "Mount backends to enable (all if null).";
      type = nullOr (listOf str);
      default = null;
    };
    monitors = mkOption {
      description = "Volume monitors to enable (all if null).";
      type = nullOr (listOf str);
      default = ["udisks2" "mtp"];
    };
    package = mkPackageOption pkgs "gvfs" {};
  };
  config = mkIf config'.enable {
    home.packages = [(symlinkJoin {
      inherit (config'.package) pname version;
      paths = [config'.package];
      postBuild = ''
        in=${config'.package}

        mkdir -p "$out/share/systemd/user/gvfs-daemon.service.d"
        cat <<-EOF > $out/share/systemd/user/gvfs-daemon.service.d/10-environment.conf
					[Service]
					Environment=GVFS_MOUNTABLE_DIR=$out/share/gvfs/mounts
					Environment=GVFS_MONITOR_DIR=$out/share/gvfs/remote-volume-monitors
				EOF

        ${optionalString (config'.mountables != null) ''
          rm -rf "$out/share/gvfs/mounts"
          mkdir -p "$out/share/gvfs/mounts"
          for name in ${escapeShellArgs config'.mountables}; do
            ln -sfn "$in/share/gvfs/mounts/$name.mount" \
                    "$out/share/gvfs/mounts"
          done
        ''}
        ${optionalString (config'.monitors != null) ''
          rm -rf "$out/share/gvfs/remote-volume-monitors"
          mkdir -p "$out/share/gvfs/remote-volume-monitors"
          for name in ${escapeShellArgs config'.monitors}; do
            ln -sfn "$in/share/gvfs/remote-volume-monitors/$name.monitor" \
                    "$out/share/gvfs/remote-volume-monitors"
          done
        ''}
      '';
    })];
  };
}
