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

{ pluginRegistry }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  prefs = {
    fontFamily = "Inter";
    clock12h = true;

    location = {
      name = "القاهرة";
      # Strings: Nix prints floats with 6 significant digits.
      latitude = "30.0443879";
      longitude = "31.2357257";
    };

    wallpaper = {
      default = "Pictures/wallpapers/1351306.png"; # relative to the home directory
      cycleSeconds = 3 * 60;
    };

    bar = {
      position = "right";
      opacity = 0.7;
      fontScale = 1.4;
      padding = 16;
      outlineThickness = 2;
    };

    dock = {
      position = "left";
      iconSize = 36;
      itemSpacing = 4;
      # App ids as DMS records them when pinning (`dms ipc call settings dumpSession`); they are the
      # apps' StartupWMClass or desktop ids.
      pinned = [
        "firefox"
        "com.mitchellh.ghostty"
        "github-copilot-app"
        "BiglyBT Extreme Mod"
        "microsoft-edge"
        "code"
        "thunderbird"
      ];
    };

    # Seconds; 0 = never. screenOffLocked: monitors off this long after locking.
    idle = {
      ac = {
        lock = 5 * 60;
        screenOff = 10 * 60;
        suspend = 30 * 60;
        screenOffLocked = 60;
      };
      battery = {
        lock = 60;
        screenOff = 60;
        suspend = 15 * 60;
        screenOffLocked = 30;
      };
    };
  };
  positions = {
    top = 0;
    bottom = 1;
    left = 2;
    right = 3;
  };

  # Main-bar changes on top of DMS's stock bar, which is read from the installed DMS at build time
  # (see xdg.configFile."dms/settings.json" below; stock values: SettingsSpec.js barConfigs).
  # replaceDefaults = false: list entries are merged into the stock lists, either as an id
  # (appended) or { id; before|after = <stock id>; } (placed next to it; a missing anchor fails
  # the build); true: lists replace the stock ones. Scalars always replace. { } = stock bar.
  barOverrides = {
    replaceDefaults = false;
    position = positions.${prefs.bar.position};
    leftWidgets = [ "runningApps" ];
    rightWidgets = [
      # current layout (EN/AR), click to switch
      {
        id = "keyboard_layout_name";
        before = "notificationButton";
      }
    ];
    innerPadding = prefs.bar.padding;
    followInterfaceStyle = true;
    transparency = prefs.bar.opacity;
    widgetOutlineEnabled = true;
    widgetOutlineColor = "secondary";
    widgetOutlineThickness = prefs.bar.outlineThickness;
    fontScale = prefs.bar.fontScale;
    iconScale = 1.12;
    # Island layout; unset island* keys fall back to BarWidgetDefaults.js ISLAND_DEFAULTS.
    island = true;
    islandAlongOffset = -199;
    islandReserveThickness = 42;
    islandDashTabs = true;
    islandSatelliteGothCorners = false;
    islandSystemOsd = false;
    islandNotificationPopups = true;
  };

  # Changes to the settings DMS loads whole (a declared value replaces its default, so a partial
  # one would drop the rest), applied by dms-settings.js on top of the stock default:
  # objects are deep-merged, lists of { id, ... } are patched per id (unknown id fails the build).
  lockWidgetPatches = [
    {
      id = "lock_date";
      enabled = true;
    }
    {
      id = "lock_power";
      enabled = true;
    }
  ];
  defaultPatches = {
    # DMS rewrites niri/dms/cursor.kdl from these; same values as home/desktop/niri.nix.
    cursorSettings =
      let
        inherit (config.programs.niri.settings) cursor;
      in
      {
        inherit (cursor) theme size;
        niri = {
          hideWhenTyping = cursor.hide-when-typing;
          hideAfterInactiveMs = cursor.hide-after-inactive-ms;
        };
      };
    weatherProviders = [
      {
        id = "openmeteo";
        enabled = false;
      }
      {
        id = "metno";
        enabled = true;
      }
    ];
    lockScreenWidgetInstances = lockWidgetPatches;
    # The greeter mirrors the lock screen's widgets (minus notifications); synced to the login
    # screen by services.displayManager.dux-greeter.configHome (nixos/desktop/dms.nix).
    greeterWidgetInstances = lockWidgetPatches;
  };
in
{
  options.nixConfig.desktop.dms.enable =
    lib.mkEnableOption "Dux Modular Shell (bar, launcher, notifications)";

  config = lib.mkIf config.nixConfig.desktop.dms.enable {
    # DMS matugen writes these from the wallpaper (matugenTemplateGtk / matugenTemplateKcolorscheme
    # below); the same imports DMS's "Apply GTK/Qt colors" buttons would set, but declarative
    # (DMS detects and respects the home-manager symlinks). Dark/light is runtime-only (DMS toggle):
    # DMS switches gtk-theme between adw-gtk3 and adw-gtk3-dark and syncs the portal color-scheme.
    nixConfig.desktop.niri.palette = {
      gtkCss = "dank-colors.css";
      kdeColorScheme = "DankMatugen";
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
      # Keys DMS loads whole (cursorSettings, weatherProviders, lock/greeter widgets) go in
      # defaultPatches above instead; the build fails if one is also set here.
      settings = {
        clockFormat = if prefs.clock12h then "12h" else "24h"; # auto | 12h | 24h
        firstDayOfWeek = 6; # 0 Sunday … 6 Saturday; -1 = locale
        inherit (prefs) fontFamily;
        fontWeight = 600;
        fontScale = 1.12;
        radiusStrength = 24; # corner roundness, %
        # niri window gaps (px), written to niri/dms/layout.kdl. -1 = auto: max(4, bar spacing);
        # -2 = off: niri's own config decides.
        niriLayoutGapsOverride = config.programs.niri.settings.layout.gaps;
        modalDarkenBackground = false;
        dankLauncherV2BorderEnabled = true;
        powerMenuGridLayout = true;
        lockScreenFontFamily = prefs.fontFamily;
        lockScreenShowPowerActions = true;
        matugenScheme = "scheme-expressive";
        # "" = first connected screen. A fixed name (e.g. "eDP-1") stops wallpaper-cycle recoloring
        # whenever that output is off (kanshi "docked" profile disables eDP-1).
        matugenTargetMonitor = ""; # Target monitor for matugen (leave empty for first connected screen)
        currentThemeCategory = "dynamic"; # generic | dynamic (wallpaper colors) | custom | registry
        currentThemeName = "dynamic"; # with category "dynamic", use "dynamic"
        runDmsMatugenTemplates = true;
        matugenTemplateGtk = true;
        # Qt colors come from the kcolorscheme template (DankMatugen.colors), see qt block above.
        matugenTemplateKcolorscheme = true;
        matugenTemplateQt5ct = false;
        matugenTemplateQt6ct = false;

        # Built-in replacement for the old dankBatteryAlerts plugin
        batteryNotifyLow = true;
        batteryChargeLimit = 60; # %, protects battery life when mostly plugged in
        keyboardNumlock = true;
        osdKeyboardLayoutEnabled = true; # OSD popup on layout switch (EN/AR)

        acMonitorTimeout = prefs.idle.ac.screenOff;
        acLockTimeout = prefs.idle.ac.lock;
        acSuspendTimeout = prefs.idle.ac.suspend;
        acPostLockMonitorTimeout = prefs.idle.ac.screenOffLocked;
        batteryMonitorTimeout = prefs.idle.battery.screenOff;
        batteryLockTimeout = prefs.idle.battery.lock;
        batterySuspendTimeout = prefs.idle.battery.suspend;
        batteryPostLockMonitorTimeout = prefs.idle.battery.screenOffLocked;

        # DMS fills the omitted dock fields from its defaults on load (DockConfig.normalize),
        # so listing only the changes is enough.
        dockConfigs = [
          {
            id = "dock";
            name = "Dock";
            enabled = true;
            position = positions.${prefs.dock.position};
            iconSize = prefs.dock.iconSize;
            itemSpacing = prefs.dock.itemSpacing;
            groupByApp = true;
            separatePinnedAndRunningApps = true;
            borderEnabled = true;
            borderOpacity = 0.7;
            borderThickness = 2;
            launcherLogoMode = "apps";
            showTrash = true;
          }
        ];
      };
      # Same rule as settings; skip runtime state keys (monitorWallpapers, launcherQueryHistory, configVersion).
      session = {
        weatherLocation = prefs.location.name;
        weatherCoordinates = "${prefs.location.latitude},${prefs.location.longitude}";
        dockPins.dock = prefs.dock.pinned;
        wallpaperPath = "${config.home.homeDirectory}/${prefs.wallpaper.default}";
        wallpaperCyclingEnabled = true;
        wallpaperCyclingInterval = prefs.wallpaper.cycleSeconds;
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
          interval = prefs.wallpaper.cycleSeconds;
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
          ];
        };
      };
    };

    # settings.json = the `settings` above + barConfigs + defaultPatches. DMS doesn't fill missing
    # fields of a declared bar (or of the other whole-loaded keys), so a partial value would break it;
    # instead dms-settings.js takes the stock values from this DMS package's SettingsSpec.js and
    # applies barOverrides/defaultPatches. Follows upstream on update, no manual sync;
    # if upstream moves a default, the build fails (not the desktop).
    xdg.configFile."dms/settings.json".source =
      let
        cfg = config.programs.dank-material-shell;
      in
      lib.mkForce (
        pkgs.runCommand "dms-settings.json"
          {
            settings = builtins.toJSON cfg.settings;
            overrides = builtins.toJSON {
              bar = barOverrides;
              patches = defaultPatches;
            };
            passAsFile = [
              "settings"
              "overrides"
            ];
            nativeBuildInputs = [ pkgs.nodejs-slim ];
          }
          ''
            node ${./dms-settings.js} \
              ${cfg.package}/share/quickshell/dms/Common/settings/SettingsSpec.js \
              $settingsPath $overridesPath $out
          ''
      );

    home.sessionVariables = {
      DMS_PRIVESC = "sudo";
    };

    # Text and code open in the DMS notepad (editors such as VS Code also claim these).
    # Merged with xdg.mimeApps in home/desktop/common.nix and home/desktop/niri.nix.
    xdg.mimeApps.defaultApplications = lib.genAttrs [
      "text/plain"
      "text/markdown"
      "application/json"
      "application/x-zerosize" # empty files
      "text/x-csrc"
      "text/x-c++src"
      "text/x-python"
      "text/x-shellscript"
    ] (_: "dev.duxlabs.shell.notepad.desktop");
  };
}
