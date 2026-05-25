{
  lib,
  pkgs,
  ...
}:
let 

backgroundCyclingInterval = 15; # in seconds

in
{
  programs.dank-material-shell = {
    enable = true;
    enableSystemMonitoring = true;
    enableVPN = true;
    enableDynamicTheming = true;
    enableAudioWavelength = true;
    enableCalendarEvents = true;
    enableClipboardPaste = true;
    managePluginSettings = true;
    systemd = {
      enable = false; # Systemd service for auto-start
      restartIfChanged = true; # Auto-restart dms.service when dank-material-shell changes
    };
    settings = {
      dynamicTheming = true;
      use24HourClock = false;
      matugenTargetMonitor = "eDP-1";
      currentThemeCategory = "dynamic";
    };
    session = {
      # TODO extract path and do NOT hardcode it
      wallpaperPath = "/home/ahmed/Pictures/wallpapers/1351306.png";
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

      # Monitor name should be dynamic per host at least
      monitorCyclingSettings = {
        "eDP-1" = {
          enabled = true;
          mode = "interval";
          interval = backgroundCyclingInterval;
        };
        "HDMI-A-1" = {
          enabled = true;
          mode = "interval";
          interval = backgroundCyclingInterval;
        };
        "DP-1" = {
          enabled = true;
          mode = "interval";
          interval = backgroundCyclingInterval;
        };
      };

    };
    clipboardSettings = {
      clearAtStartup = true;
      disabled = false;
      disableHistory = false;
      disablePersist = true;
    };
    plugins = {
      dankBatteryAlerts.enable = true;
      dockerManager.enable = false;

      # plugin-specific settings
      mediaPlayer = {
        enable = true;

        settings = {
          preferredSource = "spotify";
        };
      };
    };
    niri = {
      enableKeybinds = false;
      enableSpawn = true;

      # nix run github:AvengeMedia/DankMaterialShell/stable -- setup
      # to generate defaults
      # https://danklinux.com/docs/dankmaterialshell/nixos-flake?_highlight=filestoinclude#config-includes
      includes = {
        enable = true;

        override = true;
        originalFileName = "hm";
        filesToInclude = [
          "alttab"
          "binds"
          "colors"
          "layout"
          "outputs"
          "windowrules"
          "wpblur"
        ];
      };
    };
  };
}
