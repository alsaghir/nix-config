# NixOS entry point for asus-laptop: selects shared modules and layers host-specific settings on top.

{ pkgs, ... }:
{
  imports = [
    ../../nixos/core/boot.nix
    ../../nixos/core/core.nix
    ../../nixos/core/locale.nix
    ../../nixos/core/networking.nix

    # Host-specific hardware scan
    ./hardware-configuration.nix
    ./disko.nix

    # System profiles
    ../../nixos/desktop
    ../../nixos/hardware

    ../../nixos/services/cli.nix
    ../../nixos/services/gaming.nix
    ../../nixos/services/nix-ld.nix
    ../../nixos/services/gui-commons.nix
    ../../nixos/services/jellyfin.nix
    ../../nixos/services/pipewire.nix
    ../../nixos/services/printing.nix
    ../../nixos/services/virtualisation.nix

    # User definitions
    ../../users/user.nix
  ];

  # Laptop-only kernel choice (keep servers/VMs on default kernel)
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # Laptop memory tuning: fast compressed RAM swap; keep a small swapfile fallback
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 150;
    priority = 100;
  };
  swapDevices = [
    {
      device = "/swap/swapfiles/swapfile";
      priority = 50;
      size = 32 * 1024;
    }
  ];

  # Host-specific settings
  system.stateVersion = "25.05";
}
