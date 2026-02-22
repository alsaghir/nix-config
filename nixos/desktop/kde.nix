{
  config,
  pkgs,
  lib,
  ...
}:

let
  theme = if config.myTheme.preferDark then "breeze-dark" else "breeze";
in
{

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  services.desktopManager.plasma6.enable = true;

  # KDE Wallet for secrets storage
  security.pam.services.sddm.enableKwallet = true;

  # Explicitly disable logind idle handling to let KDE manage it
  services.logind.settings.Login = {
    IdleAction = "ignore";
    IdleActionSec = "0";
  };

  # Exclude some default KDE apps if desired
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
  ];

  # For trash support in file managers
  services.gvfs.enable = true;

  # KDE/Plasma packages and utilities
  environment.systemPackages = with pkgs; [
    # Core KDE utilities
    kdePackages.dolphin
    kdePackages.dolphin-plugins
    kdePackages.ark
    kdePackages.kcalc
    kdePackages.kcolorchooser
    kdePackages.filelight
    kdePackages.spectacle
    kdePackages.kcharselect
    kdePackages.kwallet
    kdePackages.kwalletmanager
    kdePackages.plasma-systemmonitor
    kdePackages.karousel
    kdePackages.kmail
    kdePackages.kmail-account-wizard
    kdePackages.konsole

    # System settings and theming
    kdePackages.kde-gtk-config
    kdePackages.breeze-gtk

    # Qt theming
    kdePackages.qtstyleplugin-kvantum

    # Media codecs
    ffmpeg-headless
    ffmpegthumbnailer
    gst_all_1.gst-libav
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-vaapi
    gst_all_1.gstreamer

    # Utilities
    adwaita-fonts
    imagemagick
    wl-clipboard
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.kdePackages.xdg-desktop-portal-kde
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = [
      "kde"
      "gtk"
      "*"
    ];
  };

  qt = {
    enable = true;
    platformTheme = "kde";
    style = "breeze";
  };

  networking.networkmanager.settings = {
    connectivity = {
      interval = 0;
    };
  };

  # Enable X11 for compatibility
  services.xserver.enable = true;
  services.xserver.autoRepeatDelay = 220;
  services.xserver.autoRepeatInterval = 25;
  services.xserver.videoDrivers = [
    "nvidia"
    "amdgpu"
  ];
  services.libinput.enable = true;

  # KDE Connect for phone integration (equivalent to GSConnect)
  programs.kdeconnect.enable = true;

  # Generic desktop session environment vars (Wayland + Electron + Firefox)
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # GTK dark theme preference
  environment.etc."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-application-prefer-dark-theme=${if config.myTheme.preferDark then "1" else "0"}
  '';

  environment.etc."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-application-prefer-dark-theme=${if config.myTheme.preferDark then "1" else "0"}
  '';

}
