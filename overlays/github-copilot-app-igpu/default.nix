# Hybrid-GPU hosts: glvnd prefers NVIDIA's EGL vendor (10_nvidia.json), so the
# app's WebKitGTK renderer wakes the dGPU and keeps it busy (heat, fans).
# Force Mesa EGL (iGPU). --set-default keeps it overridable per launch.
# /run/opengl-driver is NixOS-only, hence host-scoped (registry.nix).
# Extend the existing wrapGAppsHook wrapper instead of wrapProgram: a second
# wrapper changes argv[0], so the GTK app_id stops matching StartupWMClass and
# GNOME loses the icon.
{ ... }:
_final: prev: {
  github-copilot-app = prev.github-copilot-app.overrideAttrs (old: {
    preFixup = (old.preFixup or "") + ''
      gappsWrapperArgs+=(
        --set-default __EGL_VENDOR_LIBRARY_FILENAMES
        /run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json
      )
    '';
  });
}
