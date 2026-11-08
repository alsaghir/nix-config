# Off by default; enabled per host (nixConfig.hardware.<file>.enable).
{
  imports = [
    ./asus.nix
    ./bluetooth.nix
    ./nvidia-hybrid.nix
  ];
}
