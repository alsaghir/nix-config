# Every pkgs/<name>/package.nix as pkgs.<name>, named and called the way nixpkgs' pkgs/by-name
# does, so a package moves upstream unchanged; delete its directory once nixpkgs has it.
# Also the source of flake.nix's `packages` output.
# prev.lib: the attribute names must not depend on `final` (infinite recursion); the packages
# themselves are still called with `final`, so they see every overlay.
final: prev:
prev.lib.packagesFromDirectoryRecursive {
  inherit (final) callPackage;
  directory = ../pkgs;
}
