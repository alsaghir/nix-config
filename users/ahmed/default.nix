{
  userConfig,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ../../home/cli.nix
    ../../home/gnome.nix
    ../../home/gui-commons.nix
    ../../home/ssh.nix
    ../../home/flatpak.nix
  ];

  home.username = userConfig.username;
  home.homeDirectory = userConfig.homeDirectory;
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
}
