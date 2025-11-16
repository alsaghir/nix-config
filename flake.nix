{
  description = "Zephyrus G15 – NixOS + Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs"; # Use the SAME nixpkgs input (commit/revision) that my top-level flake uses
      # “follows” is a feature of the flake input specification. It is not a Nix language keyword. It simply aliases one input’s revision to another.
    };
  };

  # nixpkgs-unstable defined in inputs and here it represents the root of the nixpkgs source tree at the unstable channel commit pinned in flake.lock
  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }:
    let
      # Import the helper function from lib
      lib = import ./lib;

      # The system architecture for your machines.
      system = "x86_64-linux";

      # Create a pkgs instance for unstable packages
      # `import` turns that into the exported function defined by nixpkgs (the big package set generator)
      pkgsUnstable = import nixpkgs-unstable { # loads `default.nix` from that source tree. In `nixpkgs`, `default.nix` is a function that expects an attribute set.
        inherit system; # syntactic sugar for system = system;
        config.allowUnfree = true;
      };
    in
    {
   
      # Using the helper function makes this section clean and scalable.
      nixosConfigurations = {
        laptop = lib.mkNixosSystem {
          
          inherit nixpkgs system pkgsUnstable;

          modules = [
            # This is the main entry point for your laptop configuration.
            ./hosts/laptop

            # Enable Home Manager for this host. Import HM as a NixOS module so 'home-manager.*' options exist.
            # HM flake publishes several outputs. One is an attr set named nixosModules which contains a module called home-manager
            # here we import that module into NixOS module.
            home-manager.nixosModules.home-manager
          ];
        };

        # Example for a future server:
        # server = lib.mkNixosSystem {
        #   inherit nixpkgs system pkgsUnstable;
        #   modules = [ ./hosts/server ];
        # };
      };
    };
}