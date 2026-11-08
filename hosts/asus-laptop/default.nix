# NixOS entry point for asus-laptop (built because registry.nix lists it and this file exists).
# Every module of nixos/ is already imported (flake.nix); this file switches features on and
# holds laptop-only facts.
{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./jellyfin.nix
  ];

  nixConfig = {
    desktop.niri.enable = true;
    hardware = {
      asus.enable = true;
      bluetooth.enable = true;
      nvidia-hybrid.enable = true;
    };
    services = {
      nix-ld.enable = true;
      virtualisation.enable = true;
    };
  };

  # PRIME bus IDs: `lspci | grep -E "VGA|3D"`, format PCI:<bus>:<device>:<function>
  hardware.nvidia.prime = {
    amdgpuBusId = "PCI:6:0:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  programs.steam.enable = true;
  services.printing.enable = true;

  # Laptop-only kernel choice (keep servers/VMs on default kernel)
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # Peripherals used with this machine
  hardware.opentabletdriver.enable = true;
  programs.droidcam.enable = true;

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

  system.stateVersion = "25.05";
}
