{ pkgs, pkgsUnstable, ... }:

{
  services.xserver.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic = {
    enable = true;
    package = pkgsUnstable.cosmic-desktop;
  };

  # 3. Ensure portals are set up for sandboxed apps.
  xdg.portal = {
    enable = true;
    extraPortals = [
      xdg-desktop-portal-cosmic
      xdg-desktop-portal-gtk
    ];
  };

  # 4. Install the Adwaita icon theme, which is recommended for COSMIC.
  environment.systemPackages = with pkgsUnstable; [
    cosmic
    cosmic-comp
    cosmic-settings
    cosmic-edit
    wl-clipboard
    gnome.adwaita-icon-theme
  ];
}
