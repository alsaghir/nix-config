{ pkgs, ... }:
{

  programs.dank-material-shell.greeter = {
    enable = true;
    compositor = {
      name = "niri";
      customConfig = ''
        output "DP-1" {
            mode "2560x1440@120"
            position x=0 y=0
        }
        output "HDMI-A-1" {
            mode "2560x1440@60"
            position x=2560 y=0
        }
        output "eDP-1" {
            mode "2560x1440@165.003"
            position x=5120 y=218
            scale 1.5
        }
      '';
    };
  };
}
