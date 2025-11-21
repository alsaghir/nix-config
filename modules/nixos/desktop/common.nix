{ config, pkgs, ... }:
{
  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;
   # Repeat configuration
  services.xserver.autoRepeatDelay = 220;      # ms before repeating
  services.xserver.autoRepeatInterval = 25;    # ms between repeats (~30/sec)
  services.xserver.videoDrivers = [ "nvidia" ];
  services.libinput.enable = true;
  programs.firefox.enable = true;

  # Generic desktop session environment vars (Wayland + Electron + Firefox)
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
    # Uncomment only if needed:
    # LIBVA_DRIVER_NAME = "nvidia";
    # __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}