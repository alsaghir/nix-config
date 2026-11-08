# Every NixOS module of this repo, wired once in flake.nix (sharedModules) for every host.
# core/ is the unconditional baseline; everything else is off until a host enables it with
# `nixConfig.<dir>.<file>.enable = true` (option path = file path). New module: add it to its dir's default.nix.
{
  imports = [
    ./core
    ./desktop
    ./hardware
    ./services
  ];
}
