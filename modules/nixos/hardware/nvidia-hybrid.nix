{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Modern graphics option
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true; # 32‑bit GL/Vulkan for Steam/Wine
  hardware.graphics.extraPackages = with pkgs; [
    # For NVIDIA/VAAPI support (required for HWA in browsers)
    nvidia-vaapi-driver
  ];

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.production;
    modesetting.enable = true;
    open = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    nvidiaSettings = true;
    prime = {
      offload.enable = true;
      # Bus IDs: get them via `lspci | grep -E "VGA|3D"`; format: PCI:<bus>:<device>:0
      amdgpuBusId = "PCI:6:0:0"; # iGPU (example from your system)
      nvidiaBusId = "PCI:1:0:0"; # dGPU
    };
  };

  # Provide an offload wrapper so you can run discrete GPU on demand:
  #   prime-run <program>
  # This avoids polluting global modules and keeps GPU bits where they belong.
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "prime-run" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec "$@"
    '')
  ];

  # https://gitlab.gnome.org/GNOME/gnome-settings-daemon/-/issues/903#note_2619256
  # TODO temp fix to prevent auto suspend after waking up
  systemd.services.nvidia-suspend = {
    # Add ConditionPathExists to the [Unit] section
    unitConfig = {
      ConditionPathExists = "/proc/driver/nvidia/suspend";
    };
    # Replace the ExecStart command in the [Service] section
    serviceConfig = {
      # The empty string "" clears the previous ExecStart command
      ExecStart = [
        ""
        "${pkgs.bash}/bin/bash -c 'echo \"suspend\" > /proc/driver/nvidia/suspend'"
      ];
    };
  };

  # Override for nvidia-resume.service
  systemd.services.nvidia-resume = {
    unitConfig = {
      ConditionPathExists = "/proc/driver/nvidia/suspend";
    };
    serviceConfig = {
      ExecStart = [
        ""
        "${pkgs.bash}/bin/bash -c 'echo \"resume\" > /proc/driver/nvidia/suspend'"
      ];
    };
  };

  # Override for nvidia-suspend-then-hibernate.service
  # Note: This is required even if you don't use this feature.
  systemd.services.nvidia-suspend-then-hibernate = {
    unitConfig = {
      ConditionPathExists = "/proc/driver/nvidia/suspend";
    };
    serviceConfig = {
      # We replace the command with the new 'suspend' echo command.
      ExecStart = [
        ""
        "${pkgs.bash}/bin/bash -c 'echo \"suspend\" > /proc/driver/nvidia/suspend'"
      ];
    };
  };
}
