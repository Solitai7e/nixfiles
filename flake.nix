{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {self, nixpkgs, home-manager, ...}:
    let inherit (nixpkgs) writeShellApplication;
        inherit (nixpkgs.lib) filter hasSuffix baseNameOf
                              systems concatMap readFile
                              genAttrs pipe nixosSystem
                              getExe;
        inherit (nixpkgs.lib.filesystem) listFilesRecursive;
        inherit (home-manager.lib) homeManagerConfiguration;
        generateImports = dirs: pipe dirs [
          (concatMap listFilesRecursive)
          (filter (hasSuffix ".nix"))
          (filter (path: baseNameOf path != "flake.nix"))
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
