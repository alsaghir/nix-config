{
  config,
  pkgs,
  lib,
  hostname,
  ...
}:

{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.gnome.gnome-keyring.enable = true;
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
    gedit
    hitori
    iagno
    tali
    totem
    gnome-tour
    cheese
    gnome-maps
    gnome-photos
    gnome-music
    gnome-user-docs
    simple-scan
    decibels
  ];

  # for trash support in file managers
  services.gvfs.enable = true;

  # Helpful GNOME tooling
  environment.systemPackages =
    with pkgs;
    [
      baobab
      dconf-editor
      ffmpeg-headless
      ffmpegthumbnailer
      file-roller
      gnome-desktop
      gnome-tweaks
      gst_all_1.gst-libav
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-ugly
      gst_all_1.gst-vaapi
      gst_all_1.gstreamer

      imagemagick
      kdePackages.qtstyleplugin-kvantum
      libsForQt5.qt5.qtgraphicaleffects
      adwaita-qt
      adwaita-qt6
      qadwaitadecorations
      qadwaitadecorations-qt6
      qgnomeplatform
      qgnomeplatform-qt6
      kdePackages.breeze
      kdePackages.breeze-gtk
      kdePackages.qt6ct
      libsForQt5.qt5ct
      nautilus
      refine
      wl-clipboard
      gnome-themes-extra
      rewaita
    ]
    ++ (with pkgs.gnomeExtensions; [
      appindicator
      battery-health-charging
      caffeine
      clipboard-indicator
      gsconnect
      gpu-supergfxctl-switch
      wallpaper-slideshow
      paperwm
      tophat
    ]);

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

  qt.enable = true;

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
  services.xserver.videoDrivers = [
    "nvidia"
    "amdgpu"
  ];
  services.xserver.excludePackages = [ pkgs.xterm ];
  services.libinput.enable = true;

  # Generic desktop session environment vars (Wayland + Electron + Firefox)
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    # QT_SCALE_FACTOR = "1";
    # QT_FONT_DPI = "96";
  };

}
