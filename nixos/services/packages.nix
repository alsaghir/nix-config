{ pkgs, lib, ... }:

let
  basePackages = with pkgs; [
    jetbrains-toolbox
    bash
    usbutils
    mesa-demos
    vulkan-tools
    fastfetch
    unzip
    just
    vim

    eza
    lsd

    ncdu
    dust

    bat
    ripgrep
    fd

    gemini-cli

    nixfmt
    statix
    deadnix
    nix-output-monitor
    nvd
    nix-diff
    nix-tree
    nix-index
    nil

    biglybt
    k9s
    kubectl
    remmina
    vscode
    antigravity
    mission-center
  ];

in
{
  environment.systemPackages = basePackages;
  programs.firefox.enable = true;

}
