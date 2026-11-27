# Every Home Manager module of this repo, wired once in flake.nix for every user@host.
# justfile.nix is always on; everything else is off until a user profile enables it with
# `nixConfig.<dir>.<file>.enable = true` (option path = file path under home/).
#
# Third-party modules are imported here too, so feature modules can set their options; each
# of them does nothing until its own enable option is set.
{ inputs }:
{
  imports = [
    inputs.dms.homeModules.dank-material-shell
    inputs.dms.homeModules.niri
    inputs.lazyvim.homeManagerModules.default
    inputs.niri.homeModules.niri
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
    inputs.plasma-manager.homeModules.plasma-manager

    ./justfile.nix
    ./ai.nix
    ./azure.nix
    ./certs.nix
    ./cli.nix
    ./dev.nix
    ./flatpak.nix
    ./git.nix
    ./lazyvim.nix
    ./ssh.nix
    ./ssh-keys.nix
    ./desktop/common.nix
    ./desktop/gnome.nix
    (inputs.nixpkgs.lib.modules.importApply ./desktop/dms.nix {
      pluginRegistry = inputs.dms-plugin-registry;
    })
    (inputs.nixpkgs.lib.modules.importApply ./desktop/niri.nix {
      qt6ctKdeAur = inputs.qt6ct-kde-aur;
      inherit (inputs.niri.lib) kdl;
    })
    ./desktop/plasma.nix
  ];
}
