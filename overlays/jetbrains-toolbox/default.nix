# overlays/jetbrains-toolbox.nix
#
# This overlay replaces the jetbrains-toolbox package from nixpkgs
# with a specific version. Instead of using overrideAttrs, which can be
# fragile, this provides a full, self-contained package definition.
# Temp fixing recent version
# Original package definition located at:
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/je/jetbrains-toolbox/package.nix

# TODO verify update script works correctly and update version and hash in this file when a new version is released.
final: prev: {
  jetbrains-toolbox =
    let
      version = "3.4.3.81140";
      src = final.fetchzip {
        url = "https://download-cdn.jetbrains.com/toolbox/jetbrains-toolbox-${version}.tar.gz";
        hash = "sha256-cDquMMb2gcRv6juEo2Ty4KgoKG5zBYtq+0mppnq4vyU=";
      };

      meta = prev.jetbrains-toolbox.meta // {
        inherit version;
      };

    in

    final.buildFHSEnv {
      pname = "jetbrains-toolbox";
      inherit version meta src;

      passthru = {
        inherit src;
        updateScript = ./update-jetbrains-toolbox.sh;
      };

      multiPkgs =
        pkgs:
        (with pkgs; [
          icu
          libappindicator-gtk3
        ])
        ++ final.appimageTools.defaultFhsEnvArgs.multiPkgs pkgs;

      runScript = ''
        ${src}/bin/jetbrains-toolbox --update-failed
      '';

      extraInstallCommands = ''
        install -Dm0644 ${src}/bin/jetbrains-toolbox.desktop -t $out/share/applications
        install -Dm0644 ${src}/bin/toolbox-tray-color.png $out/share/pixmaps/jetbrains-toolbox.png
      '';
    };
}
