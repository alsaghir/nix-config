{ pkgs, lib, ... }:

let

  basePackages = with pkgs; [   ];

in
{
  environment.systemPackages = basePackages;
  programs.evolution = {
    enable = true;
    plugins = with pkgs; [
      evolution-ews
    ];
  };

}
