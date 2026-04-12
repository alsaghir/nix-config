{ userConfig, inputs, pkgs, ... }:
{
  imports = [
    ../../home
  ];

  home.username      = userConfig.username;
  home.homeDirectory = userConfig.homeDirectory;
  home.stateVersion  = "25.05";

  programs.home-manager.enable = true;
}