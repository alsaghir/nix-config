{ config, ... }:
{
  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  environment.sessionVariables = {
    KWIN_LOW_LATENCY = "1";       # Slightly smoother frame pacing
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
  };


 # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;
   # Repeat configuration
  services.xserver.autoRepeatDelay = 220;      # ms before repeating
  services.xserver.autoRepeatInterval = 25;    # ms between repeats (~30/sec)
  services.xserver.videoDrivers = [ "nvidia" ];
  services.libinput.enable = true;
  programs.firefox.enable = true;
  
}
