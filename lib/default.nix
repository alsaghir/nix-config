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
      self,
      inputs,
      overlays ? [ ],
      hostname,
    }:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = overlays;
        config = {
          allowUnfree = true;
          nvidia.acceptLicense = true;
        };
        # Do NOT set config here to avoid changing behavior; keep your existing config in modules
      };
    in
    nixpkgs.lib.nixosSystem {
      inherit system pkgs;
      modules = modules;
      specialArgs = { inherit self inputs hostname; };

    };

  mkHomeConfig =
    {
      nixpkgs,
      home-manager,
      system,
      username,
      hostname,
      modules,
      self,
      inputs,
      overlays ? [ ],
    }:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = overlays;
        config = {
          allowUnfree = true;
        };
      };
      userConfig = registry.users.${username};
      hostConfig = registry.hosts.${hostname};
    in
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = modules;
      extraSpecialArgs = {
        inherit
          self
          inputs
          userConfig
          hostConfig
          ;
      };
    };

  mkAllHomeConfigurations =
    {
      nixpkgs,
      home-manager,
      self,
      inputs,
      overlays ? [ ],
    }:
    builtins.listToAttrs (
      builtins.concatMap (
        hostname:
        let
          hostCfg = registry.hosts.${hostname};
          system = hostCfg.system;
          userNames = builtins.attrNames hostCfg.userModules;
        in
        builtins.map (username: {
          name = "${username}@${hostname}";
          value = home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs {
              inherit system;
              overlays = overlays;
              config = {
                allowUnfree = true;
              };
            };
            modules = [
              ../users/${username}.nix
            ]
            ++ hostCfg.userModules.${username};
            extraSpecialArgs = {
              inherit self inputs;
              userConfig = registry.users.${username};
              hostConfig = hostCfg // {
                inherit hostname;
              };
            };
          };
        }) userNames
      ) (builtins.attrNames registry.hosts)
    );

  getUserConfig = username: registry.users.${username};
  getPrimaryUser = hostname: registry.hosts.${hostname}.primaryUser;
  getHostUsers = hostname: builtins.attrNames registry.hosts.${hostname}.userModules;
  getPrimaryUserConfig =
    hostname:
    let
      username = registry.hosts.${hostname}.primaryUser;
    in
    registry.users.${username};

}
