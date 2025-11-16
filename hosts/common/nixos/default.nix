# /hosts/common/nixos/default.nix
#
# This file imports all the modules that are common to all your NixOS hosts.
# This is the foundation of your reusable configuration.

{ config, pkgs, ... }:
{
  imports = [
    ./core.nix
    ./locale.nix
    ./networking.nix
  ];
}
