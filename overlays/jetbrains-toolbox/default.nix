# overlays/jetbrains-toolbox.nix
#
# This overlay replaces the jetbrains-toolbox package from nixpkgs
# with a specific version. Instead of using overrideAttrs, which can be
# fragile, this provides a full, self-contained package definition.
# Temp fixing recent version
# Original package definition located at:
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/je/jetbrains-toolbox/package.nix

final: prev: {

  jetbrains-toolbox = prev.callPackage
    ({ lib
     , stdenvNoCC
     , buildFHSEnv
     , fetchzip
     , fetchurl
     , appimageTools
     , undmg
     ,
     }:

      let
        pname = "jetbrains-toolbox";
        version = "3.2.0.65851";
        sha256 = "sha256-cIpA9FEIe9Ilnzg/m6Ryl49EwZrUGtQNorTpKgbePS4=";

        meta = {
          description = "JetBrains Toolbox";
          homepage = "https://www.jetbrains.com/toolbox-app";
          license = lib.licenses.unfree;
          sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
          maintainers = with lib.maintainers; [ ners ];
          platforms = [
            "x86_64-linux"
          ];
          mainProgram = "jetbrains-toolbox";
        };

        selectSystem =
          let
            inherit (stdenvNoCC.hostPlatform) system;
          in
          attrs: attrs.${system} or (throw "Unsupported system: ${system}");

        selectKernel =
          let
            inherit (stdenvNoCC.hostPlatform.parsed) kernel;
          in
          attrs: attrs.${kernel.name} or (throw "Unsupported kernel: ${kernel.name}");

        selectCpu =
          let
            inherit (stdenvNoCC.hostPlatform.parsed) cpu;
          in
          attrs: attrs.${cpu.name} or (throw "Unsupported CPU: ${cpu.name}");

        sourceForVersion = version:
          let
            archSuffix = selectCpu {
              x86_64 = "";
            };
            hash = selectSystem {
              x86_64-linux = sha256;
            };
          in
          selectKernel {
            linux = fetchzip {
              url = "https://download-cdn.jetbrains.com/toolbox/jetbrains-toolbox-${version}${archSuffix}.tar.gz";
              inherit hash;
            };
          };
      in
      selectKernel {
        linux =
          let
            src = sourceForVersion version;
          in
          buildFHSEnv {
            inherit pname version meta;
            passthru = {
              # Keep the update script available if you want to use it in the future
              updateScript = ./update-jetbrains-toolbox.sh;
            };
            multiPkgs = pkgs:
              with pkgs; [
                icu
                libappindicator-gtk3
              ]
              ++ appimageTools.defaultFhsEnvArgs.multiPkgs pkgs;
            runScript = "${src}/bin/jetbrains-toolbox --update-failed";

            extraInstallCommands = ''
              install -Dm0644 ${src}/bin/jetbrains-toolbox.desktop -t $out/share/applications
              install -Dm0644 ${src}/bin/toolbox-tray-color.png $out/share/pixmaps/jetbrains-toolbox.png
            '';
          };
      })
    { }; # The {} calls callPackage with an empty set of overrides.
}
