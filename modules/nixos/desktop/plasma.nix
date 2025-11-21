{ config, pkgs, ... }:
{
  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  environment.sessionVariables = {
    KWIN_LOW_LATENCY = "1";       # Slightly smoother frame pacing
  };
}
