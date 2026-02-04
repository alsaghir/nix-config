{ config, pkgs, ... }:
{
  # Steam + Gamemode (Gamescope optional)
  programs.steam.enable = true;
  programs.gamemode.enable = false;
  # programs.gamescope.enable = true; # enable if you use Gamescope sessions

  # Optional: prefer a newer Steam from unstable (if you want)
  # environment.systemPackages = lib.mkIf (pkgsUnstable != null) [
  #   pkgsUnstable.steam
  # ];
}
