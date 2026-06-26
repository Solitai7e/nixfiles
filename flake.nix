{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {self, nixpkgs, home-manager, ...}:
    let inherit (nixpkgs) writeShellApplication;
        inherit (nixpkgs.lib) systems readFile genAttrs nixosSystem filter
                              getExe pipe hasSuffix baseNameOf concatMap;
        inherit (nixpkgs.lib.filesystem) listFilesRecursive pathIsDirectory;
        inherit (home-manager.lib) homeManagerConfiguration;
        generateImports = paths: pipe paths [
          (concatMap (path:
            if pathIsDirectory path then listFilesRecursive path else [path]))
          (filter (hasSuffix ".nix"))
          (filter (path: baseNameOf path != "flake.nix"))
        ];
    in {
      lib.mkNixOS = flake: rootModule:
        let system = nixosSystem {
              modules =
                [rootModule ./lib.nix] ++
                generateImports [flake.outPath ./nixos];
              specialArgs = {
                self = flake;
                nixfiles = self;
              };
            };
            systemName = system.config.system.name;
        in {
          nixosConfigurations.${systemName} = system;
          lib.mkHome = flake: rootModule:
            let home = homeManagerConfiguration {
                  modules =
                    [rootModule ./lib.nix] ++
                    generateImports [flake.outPath ./home-manager];
                  extraSpecialArgs = {
                    self = flake;
                    nixfiles = self;
                    systemConfig = system.config;
                    inherit (system._module.args) utils;
                  };
                  inherit (system) pkgs;
                };
                inherit (home.config.home) username;
            in { homeConfigurations.${username} = home; };
        };
      apps = genAttrs systems.flakeExposed (system: {
        default = {
          type = "app";
          program = getExe (writeShellApplication {
            name = "nixfiles";
            text = readFile ./nixfiles.sh;
            runtimeInputs = with nixpkgs.legacyPackages.${system}; [
              nix coreutils util-linux
              dosfstools btrfs-progs cryptsetup
            ];
            checkPhase = "";
          });
        };
      });
    };
}
