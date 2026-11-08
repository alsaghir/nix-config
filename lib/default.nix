# Flake builders: turn registry.nix into nixosConfigurations and homeConfigurations.
#
# This is the only code that reads the registry. Modules receive its data as
# `nixConfig.*` options (lib/displays.nix, lib/users.nix), and flake inputs only
# reach profile entry points via lib.modules.importApply.
{
  lib,
  registry ? import ../registry.nix,
  usersDir ? ../users,
  hostsDir ? ../hosts,
}:

let
  # Single nixpkgs config for every package set the builders create (NixOS and Home Manager).
  nixpkgsConfig = {
    allowUnfree = true;
    nvidia.acceptLicense = true;
    permittedInsecurePackages = [
      "electron-40.10.5"
      "pnpm-10.29.2"
    ];
  };

  # One package set per host, shared by NixOS and Home Manager: the global overlays
  # plus the host's registry `extraOverlays`, so a fix needed by one machine does not
  # change the package set of the others. Host overlay files take `{ inputs }`
  # (`{ ... }` when unused) and return an overlay.
  mkPkgs =
    {
      nixpkgs,
      inputs,
      overlays,
      hostCfg,
    }:
    import nixpkgs {
      inherit (hostCfg) system;
      overlays = overlays ++ map (o: import o { inherit inputs; }) (hostCfg.extraOverlays or [ ]);
      config = nixpkgsConfig;
    };

  hostDir = hostname: hostsDir + "/${hostname}";
  hasHostDir = hostname: builtins.pathExists (hostDir hostname + "/default.nix");

  # A NixOS system for one registry host. Its entry point is hosts/<host>/default.nix (if
  # present); `sharedModules` are the modules every host gets (selected in flake.nix).
  mkNixosSystem =
    {
      nixpkgs,
      inputs,
      self,
      hostname,
      overlays ? [ ],
      sharedModules ? [ ],
      modules ? [ ],
    }:
    let
      hostCfg = registry.hosts.${hostname};
    in
    nixpkgs.lib.nixosSystem {
      inherit (hostCfg) system;
      pkgs = mkPkgs {
        inherit
          nixpkgs
          inputs
          overlays
          hostCfg
          ;
      };
      modules =
        sharedModules
        ++ [
          ./displays.nix
          ./users.nix
          {
            nixConfig = {
              displays = lib.mkDefault (hostCfg.displays or { });
              users = lib.mkDefault (
                lib.genAttrs (builtins.attrNames hostCfg.userModules) (u: registry.users.${u})
              );
              primaryUser = lib.mkDefault hostCfg.primaryUser;
            };
            networking.hostName = lib.mkDefault hostname;
            system.configurationRevision = self.rev or self.dirtyRev or null;
          }
        ]
        ++ lib.optional (hasHostDir hostname) (hostDir hostname)
        ++ modules;
    };

  # Every registry host with a hosts/<host>/default.nix becomes a NixOS system; hosts
  # without one (e.g. Home Manager on a non-NixOS machine) only get homeConfigurations.
  mkAllNixosSystems =
    args:
    lib.genAttrs (builtins.filter hasHostDir (builtins.attrNames registry.hosts)) (
      hostname: mkNixosSystem (args // { inherit hostname; })
    );

  # One `user@host` Home Manager configuration per user assigned to each registry host;
  # `sharedModules` are the modules every user@host gets (selected in flake.nix).
  mkAllHomeConfigurations =
    {
      nixpkgs,
      home-manager,
      inputs,
      overlays ? [ ],
      sharedModules ? [ ],
    }:
    builtins.listToAttrs (
      builtins.concatMap (
        hostname:
        let
          hostCfg = registry.hosts.${hostname};
          pkgs = mkPkgs {
            inherit
              nixpkgs
              inputs
              overlays
              hostCfg
              ;
          };
        in
        map (username: {
          name = "${username}@${hostname}";
          value = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            # Besides sharedModules (bound in flake.nix), profile entry points (users/<user> and
            # optional users/<user>/<host>) are the only modules that receive flake inputs.
            modules =
              let
                userCfg = registry.users.${username};
                userProfile = usersDir + "/${username}";
                hostProfile = userProfile + "/${hostname}";
              in
              sharedModules
              ++ [
                ./displays.nix
                {
                  home.username = lib.mkDefault userCfg.username;
                  home.homeDirectory = lib.mkDefault userCfg.homeDirectory;
                  nixConfig.displays = lib.mkDefault (hostCfg.displays or { });
                }
                (
                  if builtins.pathExists (userProfile + "/default.nix") then
                    lib.modules.importApply userProfile { inherit inputs; }
                  else
                    throw "Missing Home Manager profile users/${username}/default.nix for ${username}@${hostname}"
                )
              ]
              ++ lib.optional (builtins.pathExists (hostProfile + "/default.nix")) (
                lib.modules.importApply hostProfile { inherit inputs hostname; }
              )
              ++ hostCfg.userModules.${username};
          };
        }) (builtins.attrNames hostCfg.userModules)
      ) (builtins.attrNames registry.hosts)
    );
in
{
  inherit
    nixpkgsConfig
    mkNixosSystem
    mkAllNixosSystems
    mkAllHomeConfigurations
    ;
}
