# Global overlays applied to every host in this flake.
#
# Host-scoped overlays live in the registry instead (registry.nix,
# `extraOverlays`), so that a fix needed by one machine does not change the
# package set of the others.
[
  (import ./biglybt)
  (import ./posthog)
  (import ./github-copilot-app)
  (import ./pkgs.nix)
  # TEMPORARY: drop with NixOS/nixpkgs#576874 (azure-cli depends on fabric)
  (import ./fabric-invoke3.nix)
]
