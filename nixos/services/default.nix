{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
let
  flakeInputs = lib.filterAttrs (_: v: lib.isType "flake" v) inputs;

in
{
  imports = [
    ./cli.nix
    ./flatpak.nix
    ./gaming.nix
    ./nix-ld.nix
    ./packages.nix
    ./pipewire.nix
    ./printing.nix
    ./ssh.nix
    ./virtualisation.nix
  ];

  # Pin registry entries to your flake inputs to avoid network fetches during eval
  nix.registry = lib.mapAttrs (_: v: { flake = v; }) flakeInputs;

  # Provide channel-compat style NIX_PATH from the pinned registry
  nix.nixPath = lib.mapAttrsToList (key: _: "${key}=flake:${key}") config.nix.registry;

}
