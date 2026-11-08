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
  # Mounting USB drives from the file manager (gvfs's udisks2 volume monitor); explicit, not left to another module
  services.udisks2.enable = true;
}
