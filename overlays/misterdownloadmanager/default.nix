# Not in nixpkgs yet; drop this overlay once it is (pkgs/misterdownloadmanager/package.nix).
final: prev: {
  misterdownloadmanager = final.callPackage ../../pkgs/misterdownloadmanager/package.nix { };
}
