{ pkgs, lib, ... }:

let

  basePackages = with pkgs; [
    bash
    usbutils
    mesa-demos
    vulkan-tools
    fastfetch
    unzip
    just
    vim
    libinput
    openssh

    eza
    lsd
    fd
    ripgrep
    fzf
    safe-rm
    jq

    ncdu
    dust

    nixfmt
    statix
    deadnix
    nix-output-monitor
    nvd
    nix-diff
    nix-tree
    nix-index
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
