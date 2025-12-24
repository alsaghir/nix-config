{ config, pkgs, ... }:

let
  theme = if config.myTheme.preferDark then "adwaita-dark" else "adwaita";
  gtkTheme = if config.myTheme.preferDark then "Adwaita-dark" else "Adwaita";
in

{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  programs.dconf.enable = true;
  # Explicitly disable logind idle handling to let GNOME manage it.
  services.logind.settings.Login = {
    IdleAction = "ignore";
    IdleActionSec = "0";
  };

  # To disable installing GNOME's suite of applications
  # and only be left with GNOME shell.
  services.gnome.core-apps.enable = true;
  services.gnome.core-developer-tools.enable = false;
  services.gnome.games.enable = false;
  environment.gnome.excludePackages = with pkgs; [
    atomix
    cheese
    epiphany
    evince
    geary
    gedit
    gnome-terminal
    hitori
    iagno
    tali
    totem
    gnome-tour
    cheese
    gnome-maps
    gnome-contacts
    gnome-calendar
    gnome-photos
    gnome-clocks
    gnome-music
    gnome-weather
    gnome-user-docs
    gnome-calculator
    gnome-console
    simple-scan
    decibels
  ];

  # Helpful GNOME tooling
  environment.systemPackages = with pkgs; [
    adwaita-fonts
    adwaita-icon-theme
    baobab
    dconf-editor
    ffmpeg-headless
    ffmpegthumbnailer
    file-roller
    gnome-desktop
    gnome-extension-manager
    gnome-shell-extensions
    gnome-tweaks
    gst_all_1.gst-libav
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-vaapi
    gst_all_1.gstreamer
    gvfs # for trash support in file managers
    imagemagick
    kdePackages.qtstyleplugin-kvantum
    libsForQt5.qt5.qtgraphicaleffects
    nautilus
    nemo-with-extensions
    refine
    wl-clipboard
  ];

  # Wayland-friendly env
  environment.sessionVariables = {
    QT_STYLE_OVERRIDE = theme;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = [
      "gnome"
      "gtk"
      "*"
    ];
  };

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = theme;
  };

  networking.networkmanager.settings = {
    connectivity = {
      # Set to 0 to disable the check and remove the question mark
      # Or set to a reliable URL: "http://connectivity-check.ubuntu.com/"
      interval = 0;
    };
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;
  # Repeat configuration
  services.xserver.autoRepeatDelay = 220; # ms before repeating
  services.xserver.autoRepeatInterval = 25; # ms between repeats (~30/sec)
  services.xserver.videoDrivers = [ "nvidia" ];
  services.libinput.enable = true;
  programs.firefox.enable = true;
  services.desktopManager.gnome.extraGSettingsOverrides = ''
    [org.gnome.mutter]
    experimental-features=['scale-monitor-framebuffer']
  '';

  # Generic desktop session environment vars (Wayland + Electron + Firefox)
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
  };

}
