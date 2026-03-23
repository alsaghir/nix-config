{
  description = "Zephyrus G15 – NixOS";

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-flatpak = {
      url = "github:gmodena/nix-flatpak/?ref=latest";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  # nixpkgs-stable defined in inputs and here it represents the root of the nixpkgs
  # source tree at the stable channel commit pinned in flake.lock
  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      # Import the helper function from lib
      lib = import ./lib { inherit (nixpkgs) lib; };

      # The system architecture for your machines.
      system = "x86_64-linux";

      # Import the overlay once
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

      # Using the helper function makes this section clean and scalable.
      nixosConfigurations = {
        asus-laptop = lib.mkNixosSystem {

          inherit (inputs) nixpkgs;
          inherit system self inputs;

          overlays = customOverlays;

          modules = [
            # This is the main entry point for your laptop configuration.
            ./hosts/laptop/default.nix

            inputs.nix-flatpak.nixosModules.nix-flatpak
            inputs.sops-nix.nixosModules.sops
          ];
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

        # Example for future hosts:
        # desktop = lib.mkNixosSystem {
        #   inherit (inputs) nixpkgs;
        #   inherit system pkgsUnstable self;
        #   overlays = customOverlays;
        #   modules = [ ./hosts/desktop ];
        # };
      };
    };
}
