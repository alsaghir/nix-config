# ASUS/NVIDIA recipes, only meaningful on asus-laptop.
{
  justfile.recipes = ''
    # === ASUS-Specific Commands ===
    gpu-mode:
        supergfxctl --status

    gpu-offload:
        __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo -B | egrep 'OpenGL (vendor|renderer)'

    profile:
        asusctl profile --profile-get

    profile-balanced:
        asusctl profile --profile-set Balanced

    profile-performance:
        asusctl profile --profile-set Performance

    profile-quiet:
        asusctl profile --profile-set Quiet
  '';
}
