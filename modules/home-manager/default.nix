{ pkgsUnstable, ... }:
{

  imports = [
    ../../modules/home-manager/cli
    ../../modules/home-manager/flatpak.nix
    ../../modules/home-manager/gnome.nix
    ../../modules/home-manager/packages.nix
  ];

  programs.vscode = {
    enable = true;
    package = pkgsUnstable.vscode;
  };
}
