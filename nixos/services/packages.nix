{ pkgs, lib, pkgsUnstable ? null, ... }:

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

    nixfmt-rfc-style
    statix
    deadnix
    nix-output-monitor
    nvd
    nix-diff
    nix-tree
    nix-index
    nil

    podman-tui
    kubectl
    biglybt
  ];

  unstablePackages = [
    pkgsUnstable.docker-compose
    pkgsUnstable.podman-compose
    pkgsUnstable.vscode
    pkgsUnstable.antigravity
    pkgsUnstable.mission-center
  ];
in
{
  environment.systemPackages = basePackages ++ unstablePackages;
  programs.firefox.enable = true;

}
