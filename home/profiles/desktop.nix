# Graphical desktop (niri + DMS + GUI apps). Imported per host from users/<user>/<host>/default.nix,
# so headless hosts (e.g. WSL) reuse the user profile without pulling in a desktop.
{ inputs }:
{
  imports = [
    inputs.niri.homeModules.niri
    inputs.dms.homeModules.dank-material-shell
    inputs.dms.homeModules.niri
    (import ../dms.nix {
      pluginRegistry = inputs.dms-plugin-registry;
      qt6ctKdeAur = inputs.qt6ct-kde-aur;
    })
    ../niri.nix
    ../gui-commons.nix
  ];
}
