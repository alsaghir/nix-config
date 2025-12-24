{ pkgs, pkgsUnstable, ... }:
{
  home.packages = with pkgs; [
    jetbrains-toolbox
    bash
    usbutils
    mesa-demos
    vulkan-tools
    fastfetch
    terminator
    unzip
    just

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

    podman-compose
  ];
}
