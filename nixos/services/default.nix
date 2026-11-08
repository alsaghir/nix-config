# Off by default; enabled per host (nixConfig.services.<file>.enable).
{
  imports = [
    ./jellyfin.nix
    ./nix-ld.nix
    ./openssh.nix
    ./virtualisation.nix
  ];
}
