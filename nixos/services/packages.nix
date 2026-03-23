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
    libinput

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

    adwaita-fonts
    adwaita-icon-theme
    microsoft-edge
    smplayer
    bitwarden-desktop
    krita
    vlc
    vesktop
    slack
    libreoffice
    onlyoffice-desktopeditors
    kdePackages.konsole
    kdePackages.kcalc
  ];

in
{
  environment.systemPackages = basePackages;
  programs.firefox.enable = true;
  programs.evolution = {
    enable = true;
    plugins = with pkgs; [
      evolution-ews
    ];
  };

}
