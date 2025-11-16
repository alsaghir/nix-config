# Helper functions for flake.

{
  # Function to build a NixOS system configuration.
  # It takes nixpkgs, the system architecture, a list of modules, 
  # and the unstable packages as input.
  mkNixosSystem = { nixpkgs, system, modules, pkgsUnstable }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      # This makes pkgsUnstable available to all modules.
      specialArgs = { inherit pkgsUnstable; };
      inherit modules;
    };
}