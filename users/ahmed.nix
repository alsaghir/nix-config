{ ... }:
{
  imports = [
    ../modules/home-manager
  ];

  home.username = "ahmed";
  home.homeDirectory = "/home/ahmed";

  home.stateVersion = "25.05";
}
