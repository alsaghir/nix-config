{ pkgs, lib, ... }:

let

  basePackages = with pkgs; [ ];

in
{
  environment.systemPackages = basePackages;
  services.flatpak.enable = true;
  services.libinput.enable = true;

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;
  # Repeat configuration
  services.xserver.autoRepeatDelay = 220; # ms before repeating
  services.xserver.autoRepeatInterval = 25; # ms between repeats (~30/sec)
  services.xserver.videoDrivers = [
    "nvidia"
    "amdgpu"
  ];
  services.xserver.excludePackages = [ pkgs.xterm ];

  # For trash support in file managers
  services.gvfs.enable = true;
}
