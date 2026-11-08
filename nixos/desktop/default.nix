# Off by default; a host enables one desktop (e.g. nixConfig.desktop.niri), which enables the rest.
{
  imports = [
    ./common.nix
    ./dms.nix
    ./fonts.nix
    ./gnome.nix
    ./niri.nix
  ];
}
