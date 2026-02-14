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
    ../../nixos/desktop
    ../../nixos/hardware
    ../../nixos/services

    # Hardware profiles
    # ../../profiles/kernels.nix

    # User definitions
    ../../users/user.nix
    
    # Host-specific justfile
    ./justfile.nix
  ];

  system.configurationRevision = self.rev or self.dirtyRev or null;

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
  
  systemd.tmpfiles.rules = [
    # Ensure ~/.ssh exists early with correct perms/ownership
    "d ${userConfig.homeDirectory}/.ssh 0700 ${primaryUsername} users -"
  ];

  myTheme.preferDark = userConfig.preferences.theme == "dark";

  # Host-specific settings
  networking.hostName = hostname;
  system.stateVersion = "25.05";
}
