# Baseline for every NixOS host: always on, no enable options. Host parameters live under
# nixConfig.core.<file> (e.g. nixConfig.core.boot.loader).
{
  imports = [
    ./binary-cache.nix
    ./boot.nix
    ./core.nix
    ./locale.nix
    ./networking.nix
    ./users.nix
  ];
}
