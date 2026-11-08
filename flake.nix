{
  description = "NixOS and Home Manager configurations for Ahmed's machines";

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-flatpak = {
      url = "github:gmodena/nix-flatpak/?ref=latest";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lazyvim.url = "github:pfassina/lazyvim-nix";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ai-rules.url = "git+ssh://git@github.com/alsaghir/ai-rules.git";

    # Dux Modular Shell (formerly DankMaterialShell). Its home-manager module
    # is the only one supporting declarative settings/session/plugin settings.
    dms = {
      url = "github:duxlabs-dev/dux-shell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Only used for its home-manager `programs.niri.settings` module;
    # the niri package itself comes from nixpkgs (binary-cached).
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-plugin-registry = {
      url = "github:duxlabs-dev/dux-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Plain source (not a flake): locked in flake.lock, bumped by `nix flake update`.
    # Only qt6ct-shenanigans.patch is used, applied on top of nixpkgs' qt6ct.
    qt6ct-kde-aur = {
      # Explicit ref: AUR doesn't advertise HEAD's symref, so Nix would misread HEAD as a branch name.
      url = "git+https://aur.archlinux.org/qt6ct-kde.git?ref=master";
      flake = false;
    };

  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      lib = import ./lib { inherit (nixpkgs) lib; };
      customOverlays = (import ./overlays) ++ [ inputs.rust-overlay.overlays.default ];
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    in
    {

      # One system per registry host that has hosts/<host>/default.nix.
      nixosConfigurations = lib.mkAllNixosSystems {
        inherit (inputs) nixpkgs;
        inherit self inputs;
        overlays = customOverlays;
        # Every host gets these; hosts/<host>/default.nix enables features (nixConfig.*.enable).
        sharedModules = [
          inputs.disko.nixosModules.disko
          ./nixos
          (nixpkgs.lib.modules.importApply ./nixos/core/flake-pinning.nix { inherit inputs; })
        ];
      };

      homeConfigurations = lib.mkAllHomeConfigurations {
        inherit (inputs) nixpkgs home-manager;
        inherit inputs;
        overlays = customOverlays;
        # Every user@host gets these; users/<user>[/<host>] enables features (nixConfig.*.enable).
        sharedModules = [ (nixpkgs.lib.modules.importApply ./home { inherit inputs; }) ];
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      checks = forAllSystems (system: {
        composition = import ./tests/composition.nix {
          inherit system nixpkgs;
          inherit (inputs) home-manager;
        };
      });

      devShells = forAllSystems (
        system:
        import ./devshells {
          pkgs = import nixpkgs {
            inherit system;
            overlays = customOverlays;
            config = lib.nixpkgsConfig;
          };
        }
      );
    };
}
