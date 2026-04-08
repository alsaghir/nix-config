{ pkgs, lib, ... }:

let

  basePackages = with pkgs; [
    usbutils
    mesa-demos
    vulkan-tools
    unzip
    just
    
    libinput
    openssh

    safe-rm

    ncdu
    dust

    nixfmt
    statix
    deadnix
    nvd
    nix-diff
    nix-tree
    nil

  ];

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
