{
  description = "Zephyrus G15 - NixOS";

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-flatpak = {
      url = "github:gmodena/nix-flatpak/?ref=latest";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  # nixpkgs-stable defined in inputs and here it represents the root of the nixpkgs
  # source tree at the stable channel commit pinned in flake.lock
  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      lib = import ./lib { inherit (nixpkgs) lib; };
      customOverlays = import ./overlays;
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    in
    {

      nixosConfigurations = {
        asus-laptop = lib.mkNixosSystem {
          inherit (inputs) nixpkgs;
          inherit self inputs;
          hostname = "asus-laptop";
          system = "x86_64-linux";
          overlays = customOverlays;
          modules = [
            ./hosts/laptop/default.nix
            inputs.nix-flatpak.nixosModules.nix-flatpak
          ];
        };

      };

      homeConfigurations = lib.mkAllHomeConfigurations {
        inherit (inputs) nixpkgs home-manager;
        inherit self inputs;
        overlays = customOverlays;
      };

      devShells = forAllSystems (
        system:
        import ./devshells {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        }
      );
    };
}
