{ config, pkgs, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 8;
  boot.tmp.cleanOnBoot = true;
  boot.tmp.useTmpfs = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];   # Use modern CLI + flakes
    auto-optimise-store = true;                           # Deduplicate store paths
    keep-derivations = true;                              # Better caching/debugging
    keep-outputs = true;                                  # Keep build outputs referenced
    substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    max-jobs = "auto";
    cores = 0;
  };

  # Reclaim disk space periodically on every machine
  nix.gc = {
    automatic = false;                                    # Enable automatic GC / disable if nh used
    dates = "weekly";                                     # Run once per week
    options = "--delete-older-than 14d";                  # Keep 14 days of generations
    persistent = true;                                    # If the scheduled time is missed (e.g., machine is off), it runs on boot.
  };
  nix.optimise = {
  # Enables the systemd timer for full store optimization.
  automatic = true; 
  };

  nixpkgs.config.allowUnfree = true;

  # Enable zsh system-wide (required if any user’s shell = zsh)
  programs.zsh.enable = true;

  # Clean older generations
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep 5";
    };
  };

  # Base tools common to all machines (keep minimal and generic)
  environment.systemPackages = with pkgs; [
    pciutils # lspci et al. for hardware inspection; helpful everywhere
    tree # directory viewer
  ];
}
