{ config, pkgs, lib, ... }:
{
  # Modern graphics option
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;  # 32‑bit GL/Vulkan for Steam/Wine

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.production;
    modesetting.enable = true;
    open = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    nvidiaSettings = true;
    prime = {
      offload.enable = true;
      # Bus IDs: get them via `lspci | grep -E "VGA|3D"`; format: PCI:<bus>:<device>:0
      amdgpuBusId = "PCI:6:0:0";   # iGPU (example from your system)
      nvidiaBusId = "PCI:1:0:0";   # dGPU
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
}
