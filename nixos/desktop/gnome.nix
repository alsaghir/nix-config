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
  services.dbus.packages = [ pkgs.dconf ];

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

  networking.networkmanager.settings = {
    connectivity = {
      # Set to 0 to disable the check and remove the question mark
      # Or set to a reliable URL: "http://connectivity-check.ubuntu.com/"
      interval = 0;
    };
  };



  # Generic desktop session environment vars (Wayland + Electron + Firefox)
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    # QT_SCALE_FACTOR = "1";
    # QT_FONT_DPI = "96";
  };

  programs.evolution = {
    enable = true;
    plugins = with pkgs; [
      evolution-ews
    ];
  };

}
