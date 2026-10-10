{
  nixpkgs,
  home-manager,
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
        preferences.theme = "light";
      };
      guest = {
        username = "guest";
        homeDirectory = "/home/guest";
        preferences.theme = "dark";
      };
    };
    hosts = {
      first = {
        inherit system;
        primaryUser = "friend";
        userModules = {
          friend = [ ];
          guest = [ ];
        };
      };
      second = {
        inherit system;
        primaryUser = "friend";
        userModules.friend = [
          { nixConfig.theme = lib.mkForce "light"; }
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
  };
  homes = builders.mkAllHomeConfigurations {
    inherit nixpkgs home-manager;
    inputs = { };
  };
  first = homes."friend@first".config;
  second = homes."friend@second".config;
  third = homes."friend@third".config;
  guest = homes."guest@first".config;
  themeConfig =
    theme:
    (home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ../home/options.nix
        ../home/gnome.nix
        {
          home = {
            username = "friend";
            homeDirectory = "/home/friend";
            stateVersion = "25.05";
          };
          nixConfig.theme = theme;
        }
      ];
    }).config;
  dark = themeConfig "dark";
  light = themeConfig "light";
  recipes =
    (lib.evalModules {
      modules = [
        {
          options.justfile.recipes = lib.mkOption {
            type = lib.types.lines;
          };
        }
        (lib.modules.importApply ../users/ahmed/asus-laptop/justfile.nix {
          hostname = "first";
        })
        (lib.modules.importApply ../users/ahmed/asus-laptop/justfile.nix {
          hostname = "second";
        })
      ];
    }).config.justfile.recipes;
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
  systemConfig = builders.mkNixosSystem {
    inherit nixpkgs;
    inputs = { };
    self.rev = "composition-test";
    hostname = "first";
    modules = [
      { system.stateVersion = "25.05"; }
      (lib.modules.importApply ../nixos/services/nix-config.nix {
        inputs = {
          inherit nixpkgs;
          notAFlake = { };
        };
      })
    ];
  };
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
assert first.nixConfig.theme == "light";
assert guest.nixConfig.theme == "light";
assert second.home.homeDirectory == "/srv/friend";
assert second.home.sessionVariables.PROFILE_HOST == "second";
assert second.nixConfig.theme == "light";
assert third.nixConfig.theme == "dark";
assert lib.hasSuffix ".drv" homes."friend@first".activationPackage.drvPath;
assert lib.hasSuffix ".drv" homes."friend@second".activationPackage.drvPath;
assert lib.hasSuffix ".drv" homes."guest@first".activationPackage.drvPath;
assert !(first ? sops);
assert !(first.programs ? lazyvim);
assert !(first.programs ? ai-rules);
assert !(first.services ? flatpak);
assert
  pkgs.stdenv.hostPlatform.isLinux
  -> (
    dark.gtk.theme.name == "adwaita-dark"
    && dark.gtk.gtk3.extraConfig.gtk-application-prefer-dark-theme == 1
    && dark.gtk.gtk4.extraConfig.gtk-application-prefer-dark-theme == 1
    && dark.dconf.settings."org/gnome/desktop/interface".color-scheme == "prefer-dark"
    && light.gtk.theme.name == "adwaita"
    && light.gtk.gtk3.extraConfig.gtk-application-prefer-dark-theme == 0
    && light.gtk.gtk4.extraConfig.gtk-application-prefer-dark-theme == 0
    && light.dconf.settings."org/gnome/desktop/interface".color-scheme == "default"
  );
assert
  !(builtins.tryEval
    (lib.evalModules {
      modules = [
        ../home/options.nix
        { nixConfig.theme = "invalid"; }
      ];
    }).config.nixConfig.theme
  ).success;
assert !(builtins.tryEval missingProfile."ghost@first".config.home.username).success;
assert lib.hasInfix "--hostname first" recipes;
assert lib.hasInfix "--hostname second" recipes;
assert
  pkgs.stdenv.hostPlatform.isLinux
  -> (
    systemConfig.config.networking.hostName == "first"
    && systemConfig.config.system.configurationRevision == "composition-test"
    && systemConfig.pkgs.stdenv.hostPlatform.system == system
    && !systemConfig.config.nix.channel.enable
    && builtins.attrNames systemConfig.config.nix.registry == [ "nixpkgs" ]
    && systemConfig.config.nix.nixPath == [ "nixpkgs=flake:nixpkgs" ]
  );
pkgs.runCommandLocal "module-composition-check" { } ''
  touch "$out"
''
