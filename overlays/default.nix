# Global overlays applied to every host in this flake.
#
# Host-scoped overlays live in the registry instead (registry.nix,
# `extraOverlays`), so that a fix needed by one machine does not change the
# package set of the others.
[
  (import ./biglybt)
  (import ./posthog)
  (import ./github-copilot-app)

]
