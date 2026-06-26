{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {self, nixpkgs, home-manager, ...}:
    let inherit (nixpkgs.lib) filter hasSuffix baseNameOf systems concatMap
                              readFile genAttrs nixosSystem pipe
                              isPath pathIsDirectory;
        inherit (nixpkgs.lib.filesystem) listFilesRecursive;
        inherit (home-manager.lib) homeManagerConfiguration;
        generateImports = dirs: pipe dirs [
          (concatMap listFilesRecursive)
          (filter (path: hasSuffix ".nix" path && baseNameOf path != "flake.nix"))
        ];
    in {
      lib.mkNixOS = flake:
        let system = nixosSystem {
              modules = generateImports [flake.outPath ./nixos];
              specialArgs = {
                self = flake;
                nixfiles = self;
              };
            };
            systemName = system.config.system.name;
        in {
          nixosConfigurations.${systemName} = system;
          lib.mkHome = flake:
            let home = homeManagerConfiguration {
                  modules = generateImports [flake.outPath ./home-manager];
                  extraSpecialArgs = {
                    self = flake;
                    nixfiles = self;
                    systemConfig = system.config;
                  };
                  inherit (system) pkgs;
                };
                inherit (home.config.home) username;
            in { homeConfigurations.${username} = home; };
        };
      apps = genAttrs systems.flakeExposed (system:
        let pkgs = nixpkgs.legacyPackages.${system};
            nixfiles = pkgs.writeShellApplication {
              name = "nixfiles";
              text = readFile ./nixfiles.sh;
              runtimeInputs = with pkgs; [
                nix coreutils util-linux
                dosfstools btrfs-progs cryptsetup
              ];
              checkPhase = "";
            };
        in {
          default = {
            type = "app";
            program = "${nixfiles}/bin/nixfiles";
          };
        });
    };
}
