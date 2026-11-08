# Package wrappers shared by Home Manager modules. Pure functions of pkgs; no registry or flake access.
{ lib }:
{
  # Function to create a wrapper around a package that sets a clean GTK environment.
  mkCleanGtk =
    { pkgs, pkg }:
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

  # Function to create a wrapper around a package that sets the GSettings schema path.
  mkGSettingsApp =
    {
      pkgs,
      pkg,
      schemaPackages ? [
        pkgs.gsettings-desktop-schemas
        pkgs.gtk3
      ],
      primaryDesktopFile ? null,
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
          ${lib.optionalString (primaryDesktopFile != null) ''
            # Collect all MimeType values from non-primary desktop files
            allMimeTypes=""
            for desktop in "$out/share/applications"/*.desktop; do
              [ -f "$desktop" ] || continue
              name=$(basename "$desktop")
              [ "$name" = "${primaryDesktopFile}" ] && continue
              mime=$(grep "^MimeType=" "$desktop" | sed 's/^MimeType=//')
              allMimeTypes="$allMimeTypes$mime"
            done

            # Merge into primary desktop file
            primary="$out/share/applications/${primaryDesktopFile}"
            cp --remove-destination "$(readlink -f "$primary")" "$primary"
            substituteInPlace "$primary" \
              --replace-warn "${pkg}/bin/" "$out/bin/"

            if grep -q "^MimeType=" "$primary"; then
              sed -i "s|^MimeType=.*|MimeType=$allMimeTypes|" "$primary"
            else
              echo "MimeType=$allMimeTypes" >> "$primary"
            fi

            substituteInPlace "$primary" \
              --replace-quiet \
                "image/x-jpeg2000-imageimage/jpegimage/jxl" \
                "image/x-jpeg2000-image;image/jpeg;image/jxl" || true

            # Delete the now-redundant extras
            for desktop in "$out/share/applications"/*.desktop; do
              [ -f "$desktop" ] || continue
              name=$(basename "$desktop")
              [ "$name" = "${primaryDesktopFile}" ] && continue
              rm "$desktop"
            done
          ''}

          ${lib.optionalString (primaryDesktopFile == null) ''
            for desktop in "$out/share/applications"/*.desktop; do
              [ -f "$desktop" ] || continue
              cp --remove-destination "$(readlink -f "$desktop")" "$desktop"
              substituteInPlace "$desktop" \
                --replace-warn "${pkg}/bin/" "$out/bin/"
            done
          ''}
        fi
      '';
    };

}
