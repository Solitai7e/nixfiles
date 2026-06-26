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
      *) break ;;
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
  local -A OPTIONS=(version :="$nixos_version")
  getopts_nix
  local root="$1" hostname="$2"; shift 2
  mkdir -p "$root/data"/{config,state}
  write_if_missing "$root/data/config/flake.nix" <<-EOF
		{
		  inputs = {
		    nixpkgs.url = "github:NixOS/nixpkgs/nixos-$version";
		    home-manager.url = "github:nix-community/home-manager/release-$version";
		    home-manager.inputs.nixpkgs.follows = "nixpkgs";
		    nixfiles.url = "github:Solitai7e/nixfiles";
		    nixfiles.inputs.nixpkgs.follows = "nixpkgs";
		    nixfiles.inputs.home-manager.follows = "home-manager";
		  };
		  outputs = {self, nixfiles, ...}: nixfiles.lib.mkNixOS self;
		}
	EOF
  write_if_missing "$root/data/config/default.nix" <<-EOF
		{
		  system.name = $(nix_quote "$hostname");
		  system.stateVersion = "$version";
		}
	EOF
  nixos-generate-config --root "$root" --show-hardware-config --no-filesystems |
    write_if_missing "$root/data/config/hardware.nix"
}
cmd_install() {
  discardopts
  local root="$1"; shift
  local hostname; hostname="$(
    nix eval path:"$root/data/config#nixosConfigurations" \
             --raw --apply "(x: builtins.head (builtins.attrNames x))")"
  nixos-install --root "$root" \
                --flake "$root/data/config#$hostname" \
                --no-channel-copy \
                --no-root-passwd \
                --max-jobs $(($(nproc) + 2))
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
  mount -v -o noatime,subvol=root "$system_device" "$root"
  mkdir -vp "$root/boot"
  mount -v -o noatime,subvol=boot "$system_device" "$root/boot"
  mkdir -vp "$root/data"
  mount -v -o noatime,subvol=data "$system_device" "$root/data"
  mkdir -vp "$root/boot/efi"
  mount -v -o noatime,fmask=0133 "$(nth_partition "$device" 2)" "$root/boot/efi"
  mkdir -vp "$root/data/state/nix" "$root/nix"
  mount -v -o bind "$root/data/state/nix" "$root/nix"
  mkdir -vp "$root/data/state/nixos" "$root/var/lib/nixos"
  mount -v -o bind "$root/data/state/nixos" "$root/var/lib/nixos"
}
cmd_quick-partition() {
  local -A OPTIONS=(luks ?)
  getopts_nix
  local device="$1"; shift 1
  sfdisk "$device" <<< "label: gpt"
  local usable_space="$(usable_space_in_bytes "$device")"
  sfdisk "$device" <<-EOF
		type=linux size=$((usable_space / 2 ** 20 - 2))MiB
		type=uefi size=2MiB
	EOF
  if [ -n "$luks" ]; then
    luks="crypt_$(stat -c "%i" -f "$device")"
    local system_device="/dev/mapper/$luks"
    cryptsetup luksFormat --pbkdf=pbkdf2 "$(nth_partition "$device" 1)"
    cryptsetup open "$(nth_partition "$device" 1)" "$luks"
  else
    local system_device="$(nth_partition "$device" 1)"
  fi
  mkfs.btrfs "$system_device"
  local root; root="$(mktemp -d)"
  mount -v -o noatime "$system_device" "$root"
  btrfs -v subvolume create "$root"/{root,data,boot}
  umount -v "$root"
  [ -n "$luks" ] && cryptsetup close "$luks"
  mkfs.fat -v "$(nth_partition "$device" 2)"
}

"cmd_$1" "${@:2}"
