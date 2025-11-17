{ config, pkgs, ... }:
{
  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;
   # Repeat configuration
  services.xserver.autoRepeatDelay = 220;      # ms before repeating
  services.xserver.autoRepeatInterval = 25;    # ms between repeats (~30/sec)

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  services.libinput.enable = true;

  # PipeWire audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };


  programs.firefox.enable = true;

  ############################
  # Environment Variables (Minimal)
  ############################
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";     # Native Wayland Firefox/Electron hint
    KWIN_LOW_LATENCY = "1";       # Slightly smoother frame pacing
    NIXOS_OZONE_WL = "1";         # Encourage Electron apps to use Wayland
    # Uncomment only if needed:
    # LIBVA_DRIVER_NAME = "nvidia";
    # __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
