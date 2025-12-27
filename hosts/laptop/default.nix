# This is the main configuration file for your 'laptop' host.
# It imports the common configuration and then layers host-specific
# settings on top.

{
  config,
  pkgs,
  pkgsUnstable,
  lib,
  self,
  ...
}:
let
  # Import user registry helpers
  userLib = import ../../lib { inherit lib; };

  # Get primary user configuration for this host
  hostname = "asus-laptop"; # This host's identifier
  primaryUsername = userLib.getPrimaryUser hostname;
  userConfig = userLib.getPrimaryUserConfig hostname;
in
{
  imports = [
    ../../roles/common.nix # or default.nix

    # Secrets
    ../../secrets

    # Host-specific hardware scan
    ./hardware-configuration.nix

    # System profiles
    ../../modules/nixos/desktop
    ../../modules/nixos/hardware
    ../../modules/nixos/services

    # Hardware profiles
    ../../profiles/kernels.nix

    # User definitions
    ../../users/user.nix
  ];

  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Home Manager: declarative user environment layered on top of NixOS
  home-manager = {
    useGlobalPkgs = true; # Share pkgs with NixOS
    useUserPackages = true; # Keep user apps in user profile
    users.${primaryUsername} = {
      imports = [ ../../users/${primaryUsername}.nix ];
    }; # HM module for ahmed
    extraSpecialArgs = { inherit pkgsUnstable; }; # Allow a few un-stable apps in HM
  };

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
    }
  ];

  # SSH key secrets
  # Ensure ~/.ssh exists early with correct perms/ownership
  systemd.tmpfiles.rules = [
    "d ${userConfig.homeDirectory}/.ssh 0700 ${primaryUsername} users -"
  ];

  myTheme.preferDark = userConfig.preferences.theme == "dark";

  # Host-specific settings
  networking.hostName = hostname;
  system.stateVersion = "25.05";
}
