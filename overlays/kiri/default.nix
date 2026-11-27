# Not in nixpkgs yet; drop this overlay once it is (pkgs/kiri/package.nix).
final: _prev: {
  kiri = final.kdePackages.callPackage ../../pkgs/kiri/package.nix { };
}
