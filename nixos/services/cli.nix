{
  pkgs,
  lib,
  config,
  ...
}:

{

  # Shell aliases (system-wide)
  environment.shellAliases = {
    j = "just --justfile ~/.config/just/justfile";
    rm = "rm -i";
    gpustat = "nvidia-smi";
    offload-gl = "__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo -B | egrep 'OpenGL (vendor|renderer)'";
  };
}
