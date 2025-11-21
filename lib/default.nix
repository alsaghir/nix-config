# Helper functions for flake.

{
  # Function to build a NixOS system configuration.
  # It takes nixpkgs, the system architecture, a list of modules, 
  # and the stable packages as input.
  mkNixosSystem = { nixpkgs, system, modules, pkgsStable }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      # This makes pkgsStable available to all modules.
      specialArgs = { inherit pkgsStable; };
      inherit modules;
    };
}