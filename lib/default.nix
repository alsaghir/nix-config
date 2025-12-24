# Helper functions for flake.

{
  # Function to build a NixOS system configuration.
  # It takes nixpkgs, the system architecture, a list of modules, 
  # and the stable packages as input.
  mkNixosSystem = { nixpkgs, system, modules, pkgsUnstable, self, overlays ? [] }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      modules = modules ++ [{ nixpkgs.overlays = overlays; }];
      # This makes pkgsUnstable available to all modules.
      specialArgs = { inherit pkgsUnstable self; };

    };
}