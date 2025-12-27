# Helper functions
{ lib }:

let
  registry = import ../users/registry.nix;
in

{
  # Function to build a NixOS system configuration.
  # It takes nixpkgs, the system architecture, a list of modules,
  # and the stable packages as input.
  mkNixosSystem =
    {
      nixpkgs,
      system,
      modules,
      pkgsUnstable,
      self,
      overlays ? [ ],
    }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      modules = modules ++ [ { nixpkgs.overlays = overlays; } ];
      # This makes pkgsUnstable available to all modules.
      specialArgs = { inherit pkgsUnstable self; };

    };

  # Get user config by username
  # Usage: getUserConfig "ahmed"
  getUserConfig = username: registry.users.${username};

  # Get primary user for a host
  # Usage: getPrimaryUser "laptop" -> "ahmed"
  getPrimaryUser = hostname: registry.hosts.${hostname};

  # Get full user config for a host's primary user
  # Usage: getPrimaryUserConfig "laptop" -> { username = "ahmed"; ... }
  getPrimaryUserConfig =
    hostname:
    let
      username = registry.hosts.${hostname};
    in
    registry.users.${username};

  # Get all users for a host (currently just returns primary user)
  # Future: could return [ primaryUser ] ++ additionalUsers
  # Usage: getHostUsers "laptop" -> [ "ahmed" ]
  getHostUsers = hostname: [ (registry.hosts.${hostname}) ];
}
