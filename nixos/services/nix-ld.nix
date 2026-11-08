{
  config,
  lib,
  pkgs,
  ...
}:

let
  ai = pkgs.appimageTools.defaultFhsEnvArgs;
  sr = pkgs.steam-run.args;
in
{
  options.nixConfig.services.nix-ld.enable =
    lib.mkEnableOption "nix-ld with AppImage/Steam runtime libraries, for unpatched binaries";

  config = lib.mkIf config.nixConfig.services.nix-ld.enable {

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
  };
}
