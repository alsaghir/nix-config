{ config, pkgs, ... }:

{
  services.xserver = {
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  programs.dconf.enable = true;

  # To disable installing GNOME's suite of applications
  # and only be left with GNOME shell.
  services.gnome.core-apps.enable = false;
  services.gnome.core-developer-tools.enable = false;
  services.gnome.games.enable = false;
  environment.gnome.excludePackages = with pkgs; [ 
    gnome-tour
    cheese
    epiphany
    gnome-maps
    gnome-contacts
    gnome-calendar
    gnome-photos
    gnome-clocks
    gnome-music
    gnome-weather
    gnome-user-docs
  ];

  # Helpful GNOME tooling
  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnome-shell-extensions
    gnome-extension-manager
    wl-clipboard
    adwaita-icon-theme
  ];

  # Wayland-friendly env
  environment.sessionVariables = {
    QT_STYLE_OVERRIDE = "adwaita-dark";
  };

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];


  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };
}