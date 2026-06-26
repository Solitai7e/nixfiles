{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = inputs@{self, nixpkgs, ...}:
    let inherit (nixpkgs.lib) attrNames filter hasSuffix readFile genAttrs;
        inherit (nixpkgs.lib.filesystem) listFilesRecursive;
        listNixFilesRecursive = path: filter (hasSuffix ".nix") (listFilesRecursive path);
        genAttrsFromSystems = genAttrs (attrNames nixpkgs.legacyPackages);
    in {
      nixosModules.default.imports       = listNixFilesRecursive ./modules/nixos;
      homeManagerModules.default.imports = listNixFilesRecursive ./modules/home-manager;
      apps = genAttrsFromSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
            script = pkgs.writeShellApplication {
              name = "nixfiles";
              text = readFile ./nixfiles.sh;
              runtimeInputs = with pkgs; [nix coreutils util-linux cryptsetup];
            };
        in { default = { type = "app"; program = "${script}/bin/nixfiles"; }; });
    };
}
