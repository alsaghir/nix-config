# NixOS entry point for home-server (built because registry.nix lists it and this file exists).
# ASUS P8Z68-V GEN3, i7-2600K, Intel HD 3000, 16 GB. Always-on LAN box: Jellyfin,
# GNOME reachable over RDP. Installed with nixos-anywhere (README: "Installing a new host").
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./jellyfin.nix
  ];

  nixConfig = {
    # Firmware (BIOS 3603, the last) panics Linux booted via UEFI: initrd is never loaded.
    core.boot.loader = "grub-bios";
    desktop.gnome = {
      enable = true;
      remoteDesktop = {
        enable = true;
        sopsFile = ./rdp.yaml;
      };
    };
    services.openssh.enable = true;
  };

  programs.firefox.enable = true;

  # A server never sleeps (GDM would suspend it after ~15 min idle at the login screen).
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  zramSwap.enable = true;

  system.stateVersion = "26.11";
}
