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

  # remove nix-channel related tools & configs, we use flakes instead.
  nix.channel.enable = false;

  # Pin registry entries to your flake inputs to avoid network fetches during eval
  nix.registry = lib.mapAttrs (_: v: { flake = v; }) flakeInputs;

  # Provide channel-compat style NIX_PATH from the pinned registry
  nix.nixPath = lib.mapAttrsToList (key: _: "${key}=flake:${key}") config.nix.registry;

}
