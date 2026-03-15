{
  imports = [
    ./asus.nix
    ./bluetooth.nix
    ./nvidia-hybrid.nix
  ];

  hardware.opentabletdriver.enable = true;
  programs.droidcam.enable = true;
}
