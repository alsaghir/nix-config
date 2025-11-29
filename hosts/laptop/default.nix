# This is the main configuration file for your 'laptop' host.
# It imports the common configuration and then layers host-specific
# settings on top.

{
  config,
  pkgs,
  pkgsStable,
  lib,
  self,
  ...
}:
{
  imports = [
    # Import the common base configuration.
    ../common/nixos/default.nix

    # Hardware-specific configuration for this machine.
    ./hardware-configuration.nix

    # Desktop
    ../../modules/nixos/desktop/common.nix
    ../../modules/nixos/desktop/gnome.nix

    # Other Laptop-specific modules
    ../../modules/nixos/desktop/fonts.nix
    ../../modules/nixos/hardware/nvidia-hybrid.nix
    ../../modules/nixos/hardware/bluetooth.nix
    ../../modules/nixos/services/printing.nix
    ../../modules/nixos/services/gaming.nix
    ../../modules/flatpak.nix

    # OS-level user
    ../../users/ahmed/user.nix
  ];

  # Home Manager: declarative user environment layered on top of NixOS
  home-manager = {
    useGlobalPkgs = true; # Share pkgs with NixOS
    useUserPackages = true; # Keep user apps in user profile
    users.ahmed = {
      imports = [ ../../users/ahmed/default.nix ];
    }; # HM module for ahmed
    extraSpecialArgs = { inherit pkgsStable; }; # Allow a few stable apps in HM
  };

  # Laptop-only kernel choice (keep servers/VMs on default kernel)
  boot.kernelPackages = pkgs.linuxPackages_xanmod_stable;

  specialisation = {
    kernel-latest.configuration = {
      boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
    };
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

  # Asus stuff
  security.polkit.enable = true;
  services.hardware.openrgb = { 
  enable = true; 
  package = pkgs.openrgb-with-all-plugins; 
  };
  hardware.i2c.enable = true;
  services.supergfxd.enable = true;
  services = {
    asusd = {
      enable = true;
      enableUserService = true;
    };
  };
  # This service forces the desired profile after boot
  systemd.services.set-asus-profile = {
    description = "Set Default ASUS Profile to Balanced";
    
    # 1. Ensure it runs after the required services are up
    after = [ "supergfxd.service" "asusd.service" ];
    requires = [ "asusd.service" ];
    
    # 2. Tell Systemd that the service is only needed when multi-user is running
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot"; # The command runs once and then exits
      User = "root";   # Required for hardware control commands
      
      # Execute the command to set the power profile
      # You need to call 'asusctl profile' to set the power profile
      # We use 'lib.makeBinPath' to ensure the 'asusctl' binary is found in the Nix store.
      ExecStart = "${pkgs.lib.makeBinPath [ pkgs.asusctl ]}/asusctl profile --profile-set Balanced";
    };
  };
  # =========================
  # Power management (TLP)
  # =========================
  # Avoid conflicts with KDE/PowerDevil by disabling power-profiles-daemon (PPD).
  # TLP will handle low-level hardware/policy; KDE handles screen/suspend actions.
  services.power-profiles-daemon.enable = false;

  services.tlp = {
    enable = false;

    # This becomes /etc/tlp.conf (generated). Values below are safe defaults for Ryzen 5000 laptops.
    settings = {
      # CPU frequency governor + Energy Performance Preference (EPP)
      # schedutil is generally best on modern kernels; powersave + EPP=power reduces boost on battery.
      CPU_SCALING_GOVERNOR_ON_AC = "schedutil";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # Optional: if your kernel uses amd_pstate and supports opmodes, you can experiment with these.
      # Leave commented unless you want to try; not all combos are supported on all kernels.
      # CPU_DRIVER_OPMODE_ON_AC = "active";   # or "passive"
      # CPU_DRIVER_OPMODE_ON_BAT = "guided";  # or "passive"

      # Platform profile (if your firmware exposes it). Commented to avoid surprises.
      # Uncomment if supported and you want TLP to steer it.
      # PLATFORM_PROFILE_ON_AC = "performance";
      # PLATFORM_PROFILE_ON_BAT = "balanced";

      # PCIe and device runtime power management
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";

      # Enable kernel runtime PM for most PCI devices (TLP’s defaults already blacklist GPU drivers).
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";
      # Leave driver denylist at TLP defaults so GPUs are handled by their own drivers:
      # RUNTIME_PM_DRIVER_DENYLIST = "amdgpu nouveau nvidia radeon";

      # USB autosuspend (good power win). If any device misbehaves, add its VID:PID to the denylist below.
      USB_AUTOSUSPEND = 1;
      # Examples to denylist common dongles (commented until needed):
      # USB_DENYLIST = "046d:* 0bda:*"; # Logitech, Realtek
      USB_DENYLIST = "8087:*";

      # Disks/Storage power (SATA only; no effect on NVMe-only systems)
      SATA_LINKPWR_ON_AC = "med_power_with_dipm";
      SATA_LINKPWR_ON_BAT = "min_power";

      # Audio and Wi‑Fi
      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";

      # For ASUS/Zephyrus: usually only STOP is supported, with 60/80/100 allowed.
      # Pick one: 60 (max battery longevity), 80 (balanced), 100 (full).
      STOP_CHARGE_THRESH_BAT0 = "60";

      # If your kernel also exposes 'charge_control_start_threshold', you may add:
      # START_CHARGE_THRESH_BAT0 = "75";
    };
  };

  ############################
  # Audio (Low Latency PipeWire)
  ############################
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    # Optional low-latency tuning; remove if undesired
    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 32;
        "default.clock.min-quantum" = 32;
        "default.clock.max-quantum" = 128;
      };
    };
  };

system.activationScripts.patchBiglyBT = {
    text = ''
      # 1. SETUP ENVIRONMENT
      # Added 'pkgs.gzip' so tar can handle .tar.gz files
      export PATH=${lib.makeBinPath [ pkgs.flatpak pkgs.unzip pkgs.gnutar pkgs.gzip pkgs.coreutils ]}:$PATH

      echo "Hello World" >&2 
    '';
    deps = [];
  };


  # Host-specific settings
  networking.hostName = "asus-nixos";
  system.stateVersion = "25.05";
}
