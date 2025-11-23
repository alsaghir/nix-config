{ config, pkgs, ... }:

{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  programs.dconf.enable = true;
  

  # To disable installing GNOME's suite of applications
  # and only be left with GNOME shell.
  services.gnome.core-apps.enable = false;
  services.gnome.core-developer-tools.enable = false;
  services.gnome.games.enable = false;
  environment.gnome.excludePackages = with pkgs; [
    atomix # puzzle game
    cheese # webcam tool
    epiphany # web browser
    evince # document viewer
    geary # email reader
    gedit # text editor
    gnome-characters
    gnome-terminal
    hitori # sudoku game
    iagno # go game
    tali # poker game
    totem # video player
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
  ];

  # Helpful GNOME tooling
  environment.systemPackages = with pkgs; [
    nemo
    refine
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
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

}
