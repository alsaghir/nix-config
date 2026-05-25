{ pkgs, inputs, ... }:
{

  services.gnome-keyring.enable = true;

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
    settings = {
      spawn-at-startup = [
        {
          command = [
            "xwayland-satellite"
            ":0"
          ];
        }
      ];
      input = {
        focus-follows-mouse.enable = true;
      };
      outputs = {
        "DP-1" = {
          mode = {
            width = 2560;
            height = 1440;
            refresh = 120.0;
          };
          position = {
            x = 0;
            y = 0;
          };
        };
        "HDMI-A-1" = {
          mode = {
            width = 2560;
            height = 1440;
            refresh = 120.0;
          };
          position = {
            x = 2560;
            y = 0;
          };
        };
        "eDP-1" = {
          mode = {
            width = 2560;
            height = 1440;
            refresh = 165.003;
          };
          position = {
            x = 5120;
            y = 218;
          };
          scale = 1.5;
        };
      };
    };
  };

  # Required for DMS components
  home.packages = with pkgs; [
    fuzzel
    waybar
    thunar
  ];

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
    configPackages = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = [
      "gtk"
      "*"
    ];
  };
}
