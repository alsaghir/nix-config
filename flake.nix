{
  description = "Zephyrus G15 – NixOS + Home Manager";

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs"; # Use the SAME nixpkgs input (commit/revision) that my top-level flake uses
      # “follows” is a feature of the flake input specification. It is not a Nix language keyword. It simply aliases one input’s revision to another.
    };

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

      # Create a pkgs instance for stable packages
      # `import` turns that into the exported function defined by nixpkgs (the big package set generator)
      pkgsUnstable = import inputs.nixpkgs-unstable {
        # loads `default.nix` from that source tree. In `nixpkgs`, `default.nix` is a function that expects an attribute set.
        inherit system; # syntactic sugar for system = system;
        config.allowUnfree = true;
      };
    in
    {

      # Using the helper function makes this section clean and scalable.
      nixosConfigurations = {
        asus-laptop = lib.mkNixosSystem {

          inherit (inputs) nixpkgs;
          inherit system pkgsUnstable self;

          overlays = customOverlays;

          modules = [
            # This is the main entry point for your laptop configuration.
            ./hosts/laptop/default.nix

            # Enable Home Manager for this host. Import HM as a NixOS module so 'home-manager.*' options exist.
            # HM flake publishes several outputs. One is an attr set named nixosModules which contains a module called home-manager
            # here we import that module into NixOS module.
            inputs.home-manager.nixosModules.home-manager
            inputs.nix-flatpak.nixosModules.nix-flatpak
            inputs.sops-nix.nixosModules.sops
          ];
        };

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
