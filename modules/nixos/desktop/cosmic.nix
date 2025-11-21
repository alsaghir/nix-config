{ pkgs, ... }:

{
  services.xserver.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;
  programs.xwayland.enable = true;

 
  environment.systemPackages = with pkgs; [

    # Install the Adwaita icon theme, which is recommended for COSMIC.
    adwaita-icon-theme
  ];
}
