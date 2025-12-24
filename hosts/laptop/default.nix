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

    # User definitions
    ../../users/user.nix
  ];

  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Home Manager: declarative user environment layered on top of NixOS
  home-manager = {
    useGlobalPkgs = true; # Share pkgs with NixOS
    useUserPackages = true; # Keep user apps in user profile
    users.ahmed = {
      imports = [ ../../users/ahmed.nix ];
    }; # HM module for ahmed
    extraSpecialArgs = { inherit pkgsUnstable; }; # Allow a few un-stable apps in HM
  };

  # Laptop-only kernel choice (keep servers/VMs on default kernel)
  boot.kernelPackages = pkgs.linuxPackages_zen;

  specialisation = {
    # kernel-latest.configuration = {
    #   boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
    # };
    kernel-66.configuration = {
      boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_6;
    };
    kernel-zen.configuration = {
      boot.kernelPackages = lib.mkForce pkgs.linuxPackages_zen;
    };
    kernel-lqx.configuration = {
      boot.kernelPackages = lib.mkForce pkgs.linuxPackages_lqx;
    };
    kernel-xanmod-stable.configuration = {
      boot.kernelPackages = lib.mkForce pkgs.linuxPackages_xanmod_stable;
    };
    kernel-xanmod-latest.configuration = {
      boot.kernelPackages = lib.mkForce pkgs.linuxPackages_xanmod_latest;
    };
  };

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
  systemd.tmpfiles.rules =
    let
      primaryUser = builtins.head (builtins.attrNames config.home-manager.users);
    in
    [
      "d /home/${primaryUser}/.ssh 0700 ${primaryUser} users -"
    ];

  myTheme.preferDark = true;

  # Host-specific settings
  networking.hostName = "asus-nixos";
  system.stateVersion = "25.05";
}
