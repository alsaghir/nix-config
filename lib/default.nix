# Helper functions
{
  lib,
  registry ? import ../users/registry.nix,
  usersDir ? ../users,
}:

{
  mkNixosSystem =
    {
      nixpkgs,
      modules,
      self,
      inputs,
      overlays ? [ ],
      hostname,
    }:
    let
      hostCfg = registry.hosts.${hostname};
      inherit (hostCfg) system;
      pkgs = import nixpkgs {
        inherit system;
        # Host-scoped overlays (registry `extraOverlays`) are appended to the
        # global ones, so a fix needed by a single machine does not change the
        # package set of the others. They are passed an { inputs } argument so
        # they can reach flake inputs; overlays that do not need it should take
        # `{ ... }`.
        overlays =
          overlays ++ (builtins.map (o: import o { inherit inputs; }) (hostCfg.extraOverlays or [ ]));
        config = {
          allowUnfree = true;
          nvidia.acceptLicense = true;
        };
      };
    in
    nixpkgs.lib.nixosSystem {
      inherit system pkgs;
      modules = modules ++ [
        {
          networking.hostName = lib.mkDefault hostname;
          system.configurationRevision = self.rev or self.dirtyRev or null;
        }
      ];
    };

  mkAllHomeConfigurations =
    {
      nixpkgs,
      home-manager,
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
              # Host-scoped overlays (registry `extraOverlays`), appended to the
              # global ones. Same mechanism as mkNixosSystem above, so a host
              # declares its overlays once and both builders pick them up.
              overlays =
                overlays ++ (builtins.map (o: import o { inherit inputs; }) (hostCfg.extraOverlays or [ ]));
              config = {
                allowUnfree = true;
                permittedInsecurePackages = [
                  "electron-40.10.5"
                  "pnpm-10.29.2"
                ];
              };
            };
            # Profile entry points (users/<user> and optional users/<user>/<host>)
            # are the only modules that receive flake inputs; feature modules do not.
            modules =
              let
                userCfg = registry.users.${username};
                userProfile = usersDir + "/${username}";
                hostProfile = userProfile + "/${hostname}";
              in
              [
                ../home/options.nix
                {
                  home.username = lib.mkDefault userCfg.username;
                  home.homeDirectory = lib.mkDefault userCfg.homeDirectory;
                  nixConfig = lib.optionalAttrs (userCfg ? preferences.theme) {
                    theme = lib.mkDefault userCfg.preferences.theme;
                  };
                }
                (
                  if builtins.pathExists (userProfile + "/default.nix") then
                    lib.modules.importApply userProfile { inherit inputs; }
                  else
                    throw "Missing Home Manager profile users/${username}/default.nix for ${username}@${hostname}"
                )
              ]
              ++ lib.optional (builtins.pathExists (hostProfile + "/default.nix")) (
                lib.modules.importApply hostProfile { inherit inputs hostname; }
              )
              ++ hostCfg.userModules.${username};
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
