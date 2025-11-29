{ config, pkgs, ... }:
{
  users.users.ahmed = {
    isNormalUser = true;
    description = "Ahmed";
    extraGroups = [ "networkmanager" "wheel" "i2c" "video" "render" "input" ];
    packages = with pkgs; [
      kdePackages.kate
    ];
    shell = pkgs.zsh;
  };
}
