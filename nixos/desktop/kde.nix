{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.displayManager.plasma-login-manager.enable = true;
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

  # KDE/Plasma packages and utilities
  environment.systemPackages = with pkgs; [ ];

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

}
