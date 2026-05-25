{ pkgs, lib, ... }:

let

  basePackages = with pkgs; [ ];

in
{
  environment.systemPackages = basePackages;
  services.flatpak.enable = true;
  services.libinput.enable = true;

  # For trash support in file managers
  services.gvfs.enable = true;
}
