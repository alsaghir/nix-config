{ pkgs, pkgsUnstable, ... }:
{
  home.packages = with pkgs; [
    jetbrains-toolbox
    bash
    usbutils
    mesa-demos
    vulkan-tools
    fastfetch
    kdePackages.konsole
    terminator
    kdePackages.kcalc
    code-cursor
    unzip
    just

    gemini-cli
    kdePackages.kate

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
