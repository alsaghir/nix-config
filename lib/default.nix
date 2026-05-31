# Helper functions
{ lib }:

let
  registry = import ../users/registry.nix;
in

{
  # Function to build a NixOS system configuration.
  # It takes nixpkgs, the system architecture, a list of modules,
  # and the stable packages as input.
  mkNixosSystem =
    {
      nixpkgs,
      system,
      modules,
      self,
      inputs,
      overlays ? [ ],
      hostname,
    }:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = overlays;
        config = {
          allowUnfree = true;
          nvidia.acceptLicense = true;
        };
        # Do NOT set config here to avoid changing behavior; keep your existing config in modules
      };
    in
    nixpkgs.lib.nixosSystem {
      inherit system pkgs;
      modules = modules;
      specialArgs = { inherit self inputs hostname; };

    };

  mkAllHomeConfigurations =
    {
      nixpkgs,
      home-manager,
      self,
      inputs,
      overlays ? [ ],
    }:
    builtins.listToAttrs (
      builtins.concatMap (
        hostname:
        let
          hostCfg = registry.hosts.${hostname};
          system = hostCfg.system;
          userNames = builtins.attrNames hostCfg.userModules;
        in
        builtins.map (username: {
          name = "${username}@${hostname}";
          value = home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs {
              inherit system;
              overlays = overlays;
              config = {
                allowUnfree = true;
              };
            };
            modules = [
              ../users/${username}
              ../users/${username}/${hostname}
            ]
            ++ hostCfg.userModules.${username};
            extraSpecialArgs = {
              inherit self inputs;
              userConfig = registry.users.${username};
              hostConfig = hostCfg // {
                inherit hostname;
              };
            };
          };
        }) userNames
      ) (builtins.attrNames registry.hosts)
    );

  getUserConfig = username: registry.users.${username};
  getPrimaryUser = hostname: registry.hosts.${hostname}.primaryUser;
  getHostUsers = hostname: builtins.attrNames registry.hosts.${hostname}.userModules;
  getPrimaryUserConfig =
    hostname:
    let
      username = registry.hosts.${hostname}.primaryUser;
    in
    registry.users.${username};

  # Function to create a wrapper around a Qt application
  mkQtScaledApp =
    {
      pkgs,
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
