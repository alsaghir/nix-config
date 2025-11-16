{ config, pkgs, ... }:
{
  users.users.ahmed = {
    isNormalUser = true;
    description = "Ahmed";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    ];
    shell = pkgs.zsh;
  };
}
