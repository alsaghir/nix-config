{
  nixpkgs,
  home-manager,
  sops-nix,
  system,
}:
let
  inherit (nixpkgs) lib;
  pkgs = nixpkgs.legacyPackages.${system};
  registry = {
    users = {
      friend = {
        username = "friend";
        homeDirectory = "/home/friend";
      };
      guest = {
        username = "guest";
        homeDirectory = "/home/guest";
      };
    };
    hosts = {
      first = {
        inherit system;
        primaryUser = "friend";
        displays."eDP-1" = {
          width = 1920;
          height = 1080;
          x = 0;
          y = 0;
          scale = 1.25;
          internal = true;
        };
        userModules = {
          friend = [ ];
          guest = [ ];
        };
      };
      second = {
        inherit system;
        primaryUser = "friend";
        userModules.friend = [
          { home.sessionVariables.PROFILE_HOST = lib.mkForce "registry"; }
        ];
      };
      third = {
        inherit system;
        primaryUser = "friend";
        userModules.friend = [ ];
      };
    };
  };
  builders = import ../lib {
    inherit lib registry;
    usersDir = ./fixtures/users;
    hostsDir = ./fixtures/hosts;
  };
  homes = builders.mkAllHomeConfigurations {
    inherit nixpkgs home-manager;
    inputs = { };
  };
  first = homes."friend@first".config;
  second = homes."friend@second".config;
  third = homes."friend@third".config;
  guest = homes."guest@first".config;
  missingProfile =
    (import ../lib {
      inherit lib;
      usersDir = ./fixtures/users;
      registry = {
        users.ghost = {
          username = "ghost";
          homeDirectory = "/home/ghost";
        };
        hosts.first = {
          inherit system;
          primaryUser = "ghost";
          userModules.ghost = [ ];
        };
      };
    }).mkAllHomeConfigurations
      {
        inherit nixpkgs home-manager;
        inputs = { };
      };
  systems = builders.mkAllNixosSystems {
    inherit nixpkgs;
    inputs = { };
    self.rev = "composition-test";
    sharedModules = [
      sops-nix.nixosModules.sops # mirrors flake.nix; nixos/ modules set sops.* options
      ../nixos
      (lib.modules.importApply ../nixos/core/flake-pinning.nix {
        inputs = {
          inherit nixpkgs;
          notAFlake = { };
        };
      })
    ];
  };
  systemConfig = systems.first;
  sysUsers = systemConfig.config.users.users;
in
assert
  builtins.attrNames homes == [
    "friend@first"
    "friend@second"
    "friend@third"
    "guest@first"
  ];
assert first.home.username == "friend";
assert first.home.homeDirectory == "/home/friend";
assert guest.home.username == "guest";
assert second.home.homeDirectory == "/srv/friend";
assert second.home.sessionVariables.PROFILE_HOST == "registry";
assert first.nixConfig.displays."eDP-1".scale == 1.25;
assert first.nixConfig.displays."eDP-1".refresh == null;
assert third.nixConfig.displays == { };
assert lib.hasSuffix ".drv" homes."friend@first".activationPackage.drvPath;
assert lib.hasSuffix ".drv" homes."friend@second".activationPackage.drvPath;
assert lib.hasSuffix ".drv" homes."guest@first".activationPackage.drvPath;
assert !(first ? sops);
assert !(first.programs ? lazyvim);
assert !(first.programs ? ai-rules);
assert !(first.services ? flatpak);
assert
  !(builtins.tryEval
    (lib.evalModules {
      modules = [
        ../lib/displays.nix
        { nixConfig.displays."eDP-1".width = "wide"; }
      ];
    }).config.nixConfig.displays."eDP-1".width
  ).success;
assert !(builtins.tryEval missingProfile."ghost@first".config.home.username).success;
assert
  pkgs.stdenv.hostPlatform.isLinux
  -> (
    # only hosts with hosts/<host>/default.nix become NixOS systems
    builtins.attrNames systems == [ "first" ]
    && systemConfig.config.networking.hostName == "first"
    && systemConfig.config.nixConfig.displays."eDP-1".internal
    && systemConfig.config.nixConfig.primaryUser == "friend"
    && sysUsers.friend.isNormalUser
    && sysUsers.friend.home == "/home/friend"
    && sysUsers.guest.isNormalUser
    && systemConfig.config.system.configurationRevision == "composition-test"
    && systemConfig.pkgs.stdenv.hostPlatform.system == system
    && !systemConfig.config.nix.channel.enable
    # all nixos/ modules import cleanly, are off unless enabled, and take host parameters
    && !systemConfig.config.programs.niri.enable
    && !systemConfig.config.services.desktopManager.gnome.enable
    && !systemConfig.config.services.openssh.enable
    && systemConfig.config.boot.loader.systemd-boot.enable
    && !systemConfig.config.boot.loader.grub.enable
    && !systemConfig.config.hardware.bluetooth.enable
    && !systemConfig.config.services.k3s.enable
    && systemConfig.config.services.jellyfin.enable
    &&
      systemConfig.config.systemd.services.jellyfin.serviceConfig.BindReadOnlyPaths
      == [ "/srv/movies:/media/movies" ]
    && builtins.attrNames systemConfig.config.nix.registry == [ "nixpkgs" ]
    && systemConfig.config.nix.nixPath == [ "nixpkgs=flake:nixpkgs" ]
  );
pkgs.runCommandLocal "module-composition-check" { } ''
  touch "$out"
''
