{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "sdhci_pci"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [
    "kvm-amd"
    "i2c-dev"
    "i2c-piix4"
    "i2c-nct6775"
    "asus-wmi"
    "asus-nb-wmi"
    "asus-armoury"
  ];
  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.extraModulePackages = [
    config.boot.kernelPackages.nvidia_x11
    config.boot.kernelPackages.asus-ec-sensors
  ];
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "acpi_backlight=native"
    "mem_sleep_default=deep"
    "button.lid_init_state=open"
    "amdgpu.exp_hw_support=0"
    "amdgpu.powerplay=0"
    "amdgpu.dce_slow_cpu_access=1"
  ];

  # Btrfs mounts with recommended options
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/24acbbd7-a39e-4f73-8181-237a0290cc44";
    fsType = "btrfs";
    options = [
      "subvol=@"
      "compress=zstd"
      "noatime"
      "discard=async"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/24acbbd7-a39e-4f73-8181-237a0290cc44";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd"
      "noatime"
      "discard=async"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/24acbbd7-a39e-4f73-8181-237a0290cc44";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "compress=zstd"
      "noatime"
      "discard=async"
    ];
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-uuid/24acbbd7-a39e-4f73-8181-237a0290cc44";
    fsType = "btrfs";
    options = [
      "subvol=@var_log"
      "compress=zstd"
      "noatime"
      "discard=async"
    ];
  };

  # Dedicated subvolume for the swapfile, with compression disabled
  fileSystems."/swap" = {
    device = "/dev/disk/by-uuid/24acbbd7-a39e-4f73-8181-237a0290cc44";
    fsType = "btrfs";
    options = [
      "subvol=@swap"
      "compress=none"
      "noatime"
      "discard=async"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/4A74-D17E";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp3s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp4s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = true; # lib.mkDefault config.hardware.enableRedistributableFirmware;
}
