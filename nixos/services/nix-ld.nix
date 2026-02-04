{ lib, pkgs, ... }:

let
  ai = pkgs.appimageTools.defaultFhsEnvArgs;
  sr = pkgs.steam-run.args;
in
{

  # See also why we need this
  # https://github.com/NixOS/nixpkgs/issues/240444#issuecomment-1988645885
  programs.nix-ld.enable = true;

  # Use only the AppImage multiPkgs list
  programs.nix-ld.libraries =
    (ai.multiPkgs pkgs)
    ++ (sr.multiPkgs pkgs)
    ++ [
      pkgs.libsecret
      pkgs.nspr
    ];

  # If you ALSO want targetPkgs in there (usually not necessary):
  # programs.nix-ld.libraries = (ai.multiPkgs pkgs) ++ (ai.targetPkgs pkgs);

  # If you want to extend it with extra libs:
  # programs.nix-ld.libraries =
  #   (ai.multiPkgs pkgs)
  #   ++ [ pkgs.openssl ];
}
