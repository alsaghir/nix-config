{ pkgs, ... }:
{
  imports = [
    ../modules/home-manager/cli
    ../modules/home-manager/gnome
    ../modules/home-manager/packages
    ../modules/home-manager/flatpak
  ];

  home.username = "ahmed";
  home.homeDirectory = "/home/ahmed";

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
  };

  home.stateVersion = "25.05";
}
