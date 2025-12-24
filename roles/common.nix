# /hosts/common/nixos/default.nix
#
# This file imports all the modules that are common to all your NixOS hosts.
# This is the foundation of your reusable configuration.

{
  lib,
  ...
}:
{
  imports = [
    ./core.nix
    ./locale.nix
    ./networking.nix
  ];

  sops.age.keyFile = lib.mkDefault "/var/lib/sops-nix/age/keys.txt";
}
