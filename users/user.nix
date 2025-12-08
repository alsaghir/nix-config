{ config, pkgs, ... }:
{
  users.users.ahmed = {
    isNormalUser = true;
    description = "Ahmed";
    extraGroups = [ "networkmanager" "wheel" "i2c" "video" "render" "input" ];
    shell = pkgs.zsh;
  };
}
