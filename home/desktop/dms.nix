# Commands
#
# Restart dms
# dms kill; niri msg action spawn -- dms run
#
# Keys
# Mod+Shift+/
#
# Niri keybindings and commands
# niri msg action show-hotkey-overlay

{ pluginRegistry, qt6ctKdeAur }:
{
  pkgs,
  lib,
  config,
  ...
}:
let

  backgroundCyclingInterval = 3 * 60; # in seconds

  # nixpkgs' qt6ct + the AUR qt6ct-kde patch. The AUR repo is a flake input,
  # so `nix flake update` bumps it; if the patch stops applying, the build fails before switching.
  qt6ct-kde = pkgs.kdePackages.qt6ct.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [ "${qt6ctKdeAur}/qt6ct-shenanigans.patch" ];
    buildInputs = oldAttrs.buildInputs ++ [ pkgs.kdePackages.qqc2-desktop-style ];
  });

  # Main-bar changes on top of DMS's stock bar, which is read from the installed DMS at build time
  # (see xdg.configFile."dms/settings.json" below; stock values: SettingsSpec.js barConfigs).
  # replaceDefaults = false: list entries are merged into the stock lists, either as an id
  # (appended) or { id; before|after = <stock id>; } (placed next to it; a missing anchor fails
  # the build); true: lists replace the stock ones. Scalars always replace. { } = stock bar.
  barOverrides = {
    replaceDefaults = false;
    rightWidgets = [
      # current layout (EN/AR), click to switch
      {
        id = "keyboard_layout_name";
        before = "notificationButton";
      }
    ];
  };

in
{
  options.nixConfig.desktop.dms.enable =
    lib.mkEnableOption "Dux Modular Shell (bar, launcher, notifications)";

  config = lib.mkIf config.nixConfig.desktop.dms.enable {

    # GTK apps follow DMS (wallpaper) colors: DMS matugen writes gtk-{3,4}.0/dank-colors.css,
    # gtk.css imports it. Same line DMS's "Apply GTK colors" button would write, but declarative
    # (DMS detects and respects this home-manager symlink). Restart a running GTK app to see new colors.
    # Dark/light is runtime-only (DMS toggle): DMS switches gtk-theme between adw-gtk3 and
    # adw-gtk3-dark and syncs the portal color-scheme. The theme below is only the login default
    # (DMS's own default is dark); no prefer-dark-theme key, since it would pin GTK3 to dark.
    gtk =
      let
        dankColors = ''@import url("dank-colors.css");'';
      in
      {
        enable = true;
        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };
        gtk3.extraCss = dankColors;
        gtk4 = {
          theme = null;
          # libadwaita >= 1.6 widgets read --accent-* vars, which its stylesheet binds to the
          # system accent preset (gsettings accent-color, e.g. blue), ignoring our @define-color.
          # Rebinding them here (user priority) makes accents follow the DMS palette.
          extraCss = ''
            ${dankColors}
            :root {
              --accent-color: @accent_color;
              --accent-bg-color: @accent_bg_color;
              --accent-fg-color: @accent_fg_color;
            }
          '';
        };
      };

    # Qt apps follow DMS (wallpaper) colors through qt6ct-kde:
    # DMS matugen writes ~/.local/share/color-schemes/DankMatugen.colors (KDE format, needs the kde patch);
    # qt6ct.conf points at it. Same file DMS's "Apply Qt colors" button would set, but declarative.
    # enable = true also exports QT_PLUGIN_PATH (profile plugins), without which libqt6ct.so is never found.
    # Colors load at app start; restart a running Qt app to see a new palette.
    qt = {
      enable = true;
      platformTheme = {
        name = "qt6ct";
        package = qt6ct-kde; # replaces stock qt6ct (same plugin file, would collide)
      };
      qt6ctSettings.Appearance = {
        style = "Breeze"; # KDE style, honors KDE color schemes; built-in alternative: "Fusion" (plainer)
        custom_palette = true;
        color_scheme_path = "${config.xdg.dataHome}/color-schemes/DankMatugen.colors";
        icon_theme = "Adwaita"; # same as GTK
        standard_dialogs = "xdgdesktopportal"; # Nautilus file chooser
      };
    };

    programs.dank-material-shell = {
      enable = true;
      enableSystemMonitoring = true;
      enableVPN = true;
      enableDynamicTheming = true;
      enableAudioWavelength = true;
      enableCalendarEvents = true;
      managePluginSettings = true;
      systemd = {
        enable = false; # Systemd service for auto-start
        restartIfChanged = true; # Auto-restart dms.service when dank-material-shell changes
      };
      # GUI changes apply live but are not saved (settings.json is read-only).
      # To keep one: DMS Settings → export/copy JSON, then port only the keys you changed here.
      # Key reference: <dms-shell>/share/quickshell/dms/Common/settings/SettingsSpec.js
      settings = {
        density = "spacious"; # compact | comfortable | spacious
        clockFormat = "12h"; # auto | 12h | 24h
        # "" = first connected screen. A fixed name (e.g. "eDP-1") stops wallpaper-cycle recoloring
        # whenever that output is off (kanshi "docked" profile disables eDP-1).
        matugenTargetMonitor = ""; # Target monitor for matugen (leave empty for first connected screen)
        currentThemeCategory = "dynamic"; # generic | dynamic (wallpaper colors) | custom | registry
        currentThemeName = "dynamic"; # with category "dynamic", use "dynamic"
        cursorSettings = {
          theme = "Adwaita";
          size = 24;

        };
        runDmsMatugenTemplates = true;
        matugenTemplateGtk = true;
        # Qt colors come from the kcolorscheme template (DankMatugen.colors), see qt block above.
        matugenTemplateKcolorscheme = true;
        matugenTemplateQt5ct = false;
        matugenTemplateQt6ct = false;

        # Built-in replacement for the old dankBatteryAlerts plugin
        batteryNotifyLow = true;
        keyboardNumlock = true;
        osdKeyboardLayoutEnabled = true; # OSD popup on layout switch (EN/AR)
      };
      # Same rule as settings; skip runtime state keys (monitorWallpapers, dockPins, configVersion).
      session = {
        wallpaperPath = "${config.home.homeDirectory}/Pictures/wallpapers/1351306.png";
        wallpaperCyclingEnabled = true;
        wallpaperCyclingInterval = backgroundCyclingInterval;
        perMonitorWallpaper = true;
        wallpaperTransition = "random";
        includedTransitions = [
          "fade"
          "wipe"
          "disc"
          "stripes"
          "iris bloom"
          "pixelate"
          "portal"
        ];

        # One entry per display of this host (nixConfig.displays)
        monitorCyclingSettings = lib.mapAttrs (_: _: {
          enabled = true;
          mode = "interval";
          interval = backgroundCyclingInterval;
        }) config.nixConfig.displays;

      };
      clipboardSettings = {
        clearAtStartup = true;
        disabled = false;
        disableHistory = false;
        disablePersist = true;
      };

      # nix eval github:duxlabs-dev/dux-plugin-registry#packages.x86_64-linux --apply builtins.attrNames
      plugins = {
        mediaPlayer = {
          enable = true;
          src = pluginRegistry.packages.${pkgs.stdenv.hostPlatform.system}.mediaPlayer;
          settings = {
            preferredSource = "spotify";
          };
        };
      };
      niri = {
        enableKeybinds = false;
        enableSpawn = true;

        # `dms setup` generates the include files listed below
        # https://github.com/duxlabs-dev/dux-docs/blob/master/docs/dms/nixos-flake.mdx#config-includes
        includes = {
          enable = true;
          override = true;
          originalFileName = "hm";
          filesToInclude = [
            "alttab"
            "binds-next"
            "binds"
            "colors"
            "cursor"
            "layout"
            "windowrules"
            "wpblur"
            # "outputs" # DMS-managed monitors: uncomment, remove niri outputs + kanshi (home/desktop/niri.nix),
            #           # and set settings.displayProfileAutoSelect = true
            "nix-extra" # ours, not DMS-generated: see xdg.configFile."niri/dms/nix-extra.kdl" below
          ];
        };

      };
    };

    # settings.json = the `settings` above + barConfigs. DMS doesn't fill missing fields of a declared
    # bar, so a partial bar would break it; instead dms-bar.js takes the stock bar from this DMS
    # package's SettingsSpec.js and applies barOverrides. Follows upstream on update, no manual sync;
    # if upstream moves the default, the build fails (not the desktop).
    xdg.configFile."dms/settings.json".source =
      let
        cfg = config.programs.dank-material-shell;
      in
      lib.mkForce (
        pkgs.runCommand "dms-settings.json"
          {
            settings = builtins.toJSON cfg.settings;
            bar = builtins.toJSON barOverrides;
            passAsFile = [
              "settings"
              "bar"
            ];
            nativeBuildInputs = [ pkgs.nodejs-slim ];
          }
          ''
            node ${./dms-bar.js} \
              ${cfg.package}/share/quickshell/dms/Common/settings/SettingsSpec.js \
              $settingsPath $barPath $out
          ''
      );

    # Raw KDL for niri sections niri-flake's `settings` has no options for (e.g. recent-windows).
    # Shipped as one more include next to the DMS files; niri merges sections across includes.
    # Validated at build time like hm.kdl, so a typo fails `nh home build` instead of niri at runtime.
    xdg.configFile."niri/dms/nix-extra.kdl".source =
      pkgs.runCommand "nix-extra.kdl"
        {
          config = ''
            recent-windows {
                // Larger Alt-Tab previews: niri's switcher has no app icons, so make contents readable.
                // max-scale is relative (also caps height at monitor height × 0.75).
                // max-height is absolute (logical px) and only lifts niri's default of 480; 1080 = 0.75 × 1440p.
                // niri defaults (to revert): max-height 480, max-scale 0.5 — or delete this previews block.
                previews {
                    max-height 1080
                    max-scale 0.75
                }
            }
          '';
          passAsFile = [ "config" ];
          nativeBuildInputs = [ pkgs.niri ];
        }
        ''
          niri validate -c $configPath
          cp $configPath $out
        '';

    home.sessionVariables = {
      DMS_PRIVESC = "sudo";
    };

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
      configPackages = [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default = [
        "gtk"
        "*"
      ];
    };

    # Merged with xdg.mimeApps in home/desktop/common.nix
    xdg.mimeApps.defaultApplications = {
      "inode/directory" = "org.gnome.Nautilus.desktop"; # VS Code also claims folders
      "application/pdf" = "org.gnome.Papers.desktop"; # browsers, LibreOffice Draw, Krita also claim PDF
    };

    home.packages = with pkgs; [
      # Desktop apps GNOME used to provide (image viewer: nomacs, in users/ahmed/asus-laptop/default.nix).
      nautilus # file manager + portal file chooser (programs.niri.useNautilus in nixos/desktop/niri.nix)
      file-roller # archives; Nautilus "Extract"/"Compress"
      papers # PDF viewer (also its own PDF thumbnailer)
      glycin-thumbnailer # image thumbnails (same picks as the nixpkgs GNOME module)
      gst-thumbnailers # audio/video thumbnails

      adw-gtk3
      # Qt client-side decorations (QT_WAYLAND_DECORATION in home/desktop/niri.nix); qt6ct-kde comes from qt.platformTheme.
      qadwaitadecorations
      qadwaitadecorations-qt6
      kdePackages.breeze # Qt style (qt.qt6ctSettings.Appearance.style)
      nirimod
      xwayland-satellite
      gnome-tecla
      gnome-calculator
    ];

  };
}
