{
  config,
  pkgs,
  lib,
  ...
}:
let

  # https://gitlab.gnome.org/GNOME/gnome-settings-daemon/-/issues/903#note_2619256
  # TODO temp fix to prevent auto suspend after waking up
  nvidiaSuspendCondition = {
    ConditionPathExists = "/proc/driver/nvidia/suspend";
  };

  nvidiaSuspendCmd =
    action: "${pkgs.bash}/bin/bash -c 'echo \"${action}\" > /proc/driver/nvidia/suspend'";

  nvidiaSuspendServices = {
    systemd.services = {
      nvidia-suspend = {
        unitConfig = nvidiaSuspendCondition;
        serviceConfig.ExecStart = [
          ""
          (nvidiaSuspendCmd "suspend")
        ];
      };

      # Override for nvidia-resume.service
      nvidia-resume = {
        unitConfig = nvidiaSuspendCondition;
        serviceConfig.ExecStart = [
          ""
          (nvidiaSuspendCmd "resume")
        ];
      };

      # Required even if hibernate is not used
      nvidia-suspend-then-hibernate = {
        unitConfig = nvidiaSuspendCondition;
        serviceConfig.ExecStart = [
          ""
          (nvidiaSuspendCmd "suspend")
        ];
      };
    };
  };

  # https://wiki.nixos.org/wiki/NVIDIA#Graphical_corruption_and_system_crashes_on_suspend/resume
  # https://discourse.nixos.org/t/black-screen-after-suspend-hibernate-with-nvidia/54341/6
  # https://discourse.nixos.org/t/suspend-problem/54033/28
  gnomeSuspendServices = {
    systemd = {
      # See linked discussions — may be removable in the future
      services.systemd-suspend.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";

      services."gnome-suspend" = {
        description = "Suspend GNOME Shell";
        before = [
          "systemd-suspend.service"
          "systemd-hibernate.service"
          "nvidia-suspend.service"
          "nvidia-hibernate.service"
        ];
        wantedBy = [
          "systemd-suspend.service"
          "systemd-hibernate.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''${pkgs.procps}/bin/pkill -f -STOP ${pkgs.gnome-shell}/bin/gnome-shell'';
        };
      };

      services."gnome-resume" = {
        description = "Resume GNOME Shell";
        after = [
          "systemd-suspend.service"
          "systemd-hibernate.service"
          "nvidia-resume.service"
        ];
        wantedBy = [
          "systemd-suspend.service"
          "systemd-hibernate.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''${pkgs.procps}/bin/pkill -f -CONT ${pkgs.gnome-shell}/bin/gnome-shell'';
        };
      };
    };
  };

in
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
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    nvidiaPersistenced = true;
    nvidiaSettings = true;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      sync.enable = false;
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

} // nvidiaSuspendServices // gnomeSuspendServices
