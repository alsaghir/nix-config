# Pins `nix run nixpkgs#…`, NIX_PATH and the flake registry to this flake's locked inputs
# (no network lookups, same versions as the system). Needs flake inputs, so flake.nix
# binds it with importApply in sharedModules instead of nixos/core/default.nix.
{ inputs }:
{
  config,
  lib,
  ...
}:
let
  flakeInputs = lib.filterAttrs (_: v: lib.isType "flake" v) inputs;

in
{

  # remove nix-channel related tools & configs, we use flakes instead.
  nix.channel.enable = false;

  # Pin registry entries to your flake inputs to avoid network fetches during eval
  nix.registry = lib.mapAttrs (_: v: { flake = v; }) flakeInputs;

  # Provide channel-compat style NIX_PATH from the pinned registry
  nix.nixPath = lib.mapAttrsToList (key: _: "${key}=flake:${key}") config.nix.registry;

}
