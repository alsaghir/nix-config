{ pkgs, ... }:

{
  services.xserver.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;
  programs.xwayland.enable = true;

  security.polkit.enable = true;

  environment.systemPackages = with pkgs; [
    gnome-keyring
    system76-power
    # COSMIC utilities
    cosmic-applets
    cosmic-bg
    cosmic-edit
    cosmic-files
    cosmic-greeter
    cosmic-icons
    cosmic-launcher
    cosmic-notifications
    cosmic-panel
    cosmic-randr
    cosmic-screenshot
    cosmic-settings
    cosmic-term
    bottom # Better system monitor
    btop # Enhanced resource monitor

    # Wayland utilities
    waybar # Better status bar
    wofi # Application launcher
    grim # Screenshots
    slurp # Region selection
    wl-clipboard # Clipboard management
    kanshi # Display management
    bibata-cursors
    catppuccin-gtk
    # Install the Adwaita icon theme, which is recommended for COSMIC.
    adwaita-icon-theme
  ];

  programs.firefox.preferences = {
    "media.ffmpeg.vaapi.enabled" = true;
    "media.hardware-video-decoding.force-enabled" = true;
    "gfx.x11-egl.force-enabled" = true;
    "widget.dmabuf.force-enabled" = true; # Enable direct rendering via DMABUF
  };

  # Generic desktop session environment vars (Wayland + Electron + Firefox)
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
    # Uncomment only if needed:
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
    NVD_BACKEND = "wayland";
    WLR_RENDERER = "vulkan";
    GBM_BACKEND = "nvidia-drm";
  };
}
