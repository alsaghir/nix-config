{
  pkgs,
  lib,
  inputs,
  ...
}:

let
  mkQtScaledApp =
    {
      pkg,
      scale ? "1",
      fontDpi ? "96",
    }:
    pkgs.symlinkJoin {
      name = "${lib.getName pkg}-qt-scale-${builtins.replaceStrings [ "." ] [ "_" ] scale}";
      paths = [ pkg ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
          if [ -d "$out/bin" ]; then
            for f in $out/bin/*; do
              [ -f "$f" ] && [ -x "$f" ] || continue
              wrapProgram "$f" --set QT_SCALE_FACTOR ${scale} --set QT_FONT_DPI ${fontDpi}
            done
          fi

          if [ -d "$out/share/applications" ]; then
          for desktop in "$out/share/applications"/*.desktop; do
            [ -f "$desktop" ] || continue
            # Dereference the symlink so we can edit it
            cp --remove-destination "$(readlink -f "$desktop")" "$desktop"
            # Repoint Exec= from the original pkg store path to our wrapped $out/bin
            substituteInPlace "$desktop" --replace-warn "${pkg}/bin/" "$out/bin/"
          done
        fi
      '';
    };

  onlyofficeQtScale1 = mkQtScaledApp {
    pkg = pkgs.onlyoffice-desktopeditors;
    scale = "1";
    fontDpi = "96";
  };

  mkCleanGtk =
    pkg:
    pkgs.symlinkJoin {
      name = "${lib.getName pkg}-clean-gtk";
      paths = [ pkg ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        if [ -d "$out/bin" ]; then
          for f in $out/bin/*; do
            [ -f "$f" ] && [ -x "$f" ] || continue
            wrapProgram "$f" \
              --set SAL_USE_VCLPLUGIN gtk3 \
              --set GTK_THEME Adwaita:light \
              --set GTK2_RC_FILES /dev/null \
              --set XDG_CONFIG_HOME "$HOME/.config/${lib.getName pkg}-clean"
          done
        fi

        if [ -d "$out/share/applications" ]; then
          for desktop in "$out/share/applications"/*.desktop; do
            [ -f "$desktop" ] || continue
            cp --remove-destination "$(readlink -f "$desktop")" "$desktop"
            substituteInPlace "$desktop" \
              --replace-warn "${pkg}/bin/" "$out/bin/"
          done
        fi
      '';
    };

  mkGSettingsApp =
    {
      pkg,
      schemaPackages ? [
        pkgs.gsettings-desktop-schemas
        pkgs.gtk3
      ],
    }:
    let
      schemaPaths = map (p: "${p}/share/gsettings-schemas/${p.name}") schemaPackages;
      schemaPathsJoined = lib.concatStringsSep ":" schemaPaths;
    in
    pkgs.symlinkJoin {
      name = "${lib.getName pkg}-gsettings";
      paths = [ pkg ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        if [ -d "$out/bin" ]; then
          for f in $out/bin/*; do
            [ -f "$f" ] && [ -x "$f" ] || continue
            wrapProgram "$f" \
              --prefix XDG_DATA_DIRS : "${schemaPathsJoined}"
          done
        fi

        if [ -d "$out/share/applications" ]; then
          for desktop in "$out/share/applications"/*.desktop; do
            [ -f "$desktop" ] || continue
            cp --remove-destination "$(readlink -f "$desktop")" "$desktop"
            substituteInPlace "$desktop" \
              --replace-warn "${pkg}/bin/" "$out/bin/"
          done
        fi
      '';
    };

in

{
  imports = [
    inputs.sops-nix.homeManagerModules.sops

    ./cli.nix
    ./gnome.nix
    ./ssh.nix
  ];

  programs.firefox.enable = true;
  programs.ghostty.enable = true;
  programs.k9s.enable = true;
  programs.ptyxis.enable = true;
  programs.vesktop.enable = true;
  programs.vscode.enable = true;
  programs.zoxide.enable = true;
  gtk.enable = true;

  services.remmina.enable = true;

  programs.onlyoffice = {
    enable = true;
    package = onlyofficeQtScale1;
  };


  home.packages = with pkgs; [
    jetbrains-toolbox
    mailspring
    (mkGSettingsApp { pkg = nomacs; })
    kdePackages.gwenview

   
    biglybt


    antigravity
    mission-center

   
    adwaita-icon-theme
    microsoft-edge
    smplayer
    bitwarden-desktop
    (mkGSettingsApp { pkg = krita; })
    vlc

    slack
    (mkCleanGtk pkgs.libreoffice)

    kdePackages.konsole
    gradia
  ];

}
