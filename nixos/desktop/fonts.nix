{ pkgs, ... }:
{
  fonts.fontDir.enable = true;
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.hack
      hack-font
    ];
  };
}