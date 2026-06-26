#!/bin/bash
set -eu -o pipefail
shopt -s expand_aliases

alias getopts_nix='
  eval "$(for option in "${!OPTIONS[@]}"; do
    [[ ${OPTIONS["$option"]} =~ ^[:?](=(.*))? ]]
    default="${BASH_REMATCH[2]:-}"
    echo -E "declare ${option//-/_}=${default@Q}"
  done)"
  while [ $# -gt 0 ]; do
    case "$1" in
      --) break; shift ;;
      --*)
        set -- "${1#--}" "${@:2}"
        case "${OPTIONS["$1"]:0:1}" in
          "?") eval "${1//-/_}=1"; shift ;;
          ":") eval "${1//-/_}=${2@Q}"; shift 2 ;;
        esac
      ;;
      *)
        echo "${0##*/}: Unexpected ${1@Q}" >&2
        false
      ;;
    esac
  done'

alias discardopts='local -A OPTIONS; getopts_nix'

nixos_version="$(
  nix-instantiate --eval --expr "(import <nixpkgs> {}).lib.version" --raw \
    | grep -oE "^[0-9]+\.[0-9]+")"

nixos_system="$(
  nix-instantiate --eval --expr "(import <nixpkgs> {}).stdenv.hostPlatform.system" --raw)"

nix_quote() {
  nix-instantiate --eval --expr "{x}: x" --argstr x "$*"
}
write_if_missing() {
  local path="$1"; shift
  [ -e "$path" ] && return
  cat > "$path"
}
usable_space_in_bytes() {
  local device="$1"; shift
  local -A fields;
  local field value; while IFS=" :" read -r field value; do
    fields["$field"]="$value"
  done < <(sfdisk -d "$device")
  local sectors=$((fields["last-lba"] - fields["first-lba"]))
  echo -E $((sectors * fields["sector-size"]))
}
nth_partition() {
  local device="$1" n=$(($2)); shift 2
  if [[ $device =~ [0-9]$ ]]
    then echo -E "${device}p$n"
    else echo -E "$device$n"
  fi
}

cmd_generate-config() {
  local -A OPTIONS=(root :="/mnt" version :="$nixos_version")
  getopts_nix
  local hostname="$1"; shift
  mkdir -p "$root/data"/{configuration,state}
  write_if_missing "$root/data/configuration/flake.nix" <<-EOF
		{
		  inputs = {
		    nixpkgs.url = "github:NixOS/nixpkgs/nixos-$version";
		    nixfiles.url = "github:Solitai7e/nixfiles";
		    nixfiles.inputs.nixpkgs.follows = "nixpkgs";
		  };
		  outputs = inputs@{self, nixpkgs, nixfiles, ...}: {
		    nixosConfigurations.$(nix_quote "$hostname") = nixpkgs.lib.nixosSystem {
		      modules = builtins.attrValues nixfiles.nixosModules ++ [{
		        system.name = $(nix_quote "$hostname");
		        system.stateVersion = "$version";
		        imports = [
		          ./configuration.nix
		          ./hardware-configuration.nix
		        ];
		      }];
		    };
		  };
		}
	EOF
  write_if_missing "$root/data/configuration/configuration.nix" <<-EOF
		{}
	EOF
  nixos-generate-config --root "$root" --show-hardware-config --no-filesystems |
    write_if_missing "$root/data/configuration/hardware-configuration.nix"
}
cmd_install() {
  discardopts
  local root="$1"; shift
  nixos-install --root "$root" --no-channel-copy --max-jobs $(($(nproc) + 2))
}
cmd_quick-mount() {
  local -A OPTIONS=(luks :)
  getopts_nix
  local device="$1" root="$2"; shift 2
  if [ -n "$luks" ]; then
    local system_device="/dev/mapper/$luks"
    cryptsetup open "$(nth_partition "$device" 1)" "$luks"
  else
    local system_device="$(nth_partition "$device" 1)"
  fi
  mount -o noatime,subvol=root "$system_device" "$root"
  mount -o noatime,subvol=boot "$system_device" "$root/boot"
  mount -o noatime,subvol=data "$system_device" "$root/data"
  mount -o noatime,fmask=0133 "$(nth_partition "$device" 2)" "$root/boot/efi"
}
cmd_quick-partition() {
  local -A OPTIONS=(luks :)
  getopts_nix
  local device="$1"; shift 1
  sfdisk "$device" <<< "label: gpt"
  local usable_space="$(usable_space_in_bytes "$device")"
  sfdisk "$device" <<-EOF
		type=linux size=$((usable_space / 2 ** 20 - 2))MiB
		type=uefi size=2MiB
	EOF
  if [ -n "$luks" ]; then
    local system_device="/dev/mapper/$luks"
    cryptsetup luksFormat "$(nth_partition "$device" 1)"
    cryptsetup open "$(nth_partition "$device" 1)" "$luks"
  else
    local system_device="$(nth_partition "$device" 1)"
  fi
  mkfs.btrfs "$system_device";
  mount -o noatime "$system_device" "$root"
  btrfs subvolume create "$root"/{root,data,boot}
  mkdir -p "$root/root"/{data,boot{,/efi}}
  umount "$root"
  cryptsetup close "$luks"
  mkfs.fat "$(nth_partition "$device" 2)"
}

eval "shift; cmd_${1@Q} \"$@\""
