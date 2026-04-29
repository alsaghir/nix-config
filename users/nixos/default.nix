{ userConfig, inputs, pkgs, ... }:
{
  imports = [
     ../../home/cli.nix
  ];

  home.username      = userConfig.username;
  home.homeDirectory = userConfig.homeDirectory;
  home.stateVersion  = "25.11";

  programs.home-manager.enable = true;
}