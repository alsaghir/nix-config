{
  lib,
  pkgs,
  config,
  userConfig,
  inputs,
  ...
}:
let

  backgroundCyclingInterval = 5 * 60; # in seconds

  qt6ct-kde = pkgs.kdePackages.qt6ct.overrideAttrs (oldAttrs: {
    patches =
      let
        patchRepo = pkgs.fetchgit {
          url = "https://aur.archlinux.org/qt6ct-kde.git";
          rev = "refs/heads/master";
          hash = "sha256-XyiIC2xUImJOxdrHz6Vh1vGOuKiJvVjwovYqkXEgo40=";
        };
      in
      (oldAttrs.patches or [ ]) ++ [ (patchRepo + "/qt6ct-shenanigans.patch") ];
    buildInputs = oldAttrs.buildInputs ++ [ pkgs.kdePackages.qqc2-desktop-style ];
  });

in
{

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4 = {
      theme = null;
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };
  };

  qt = {
    platformTheme = "qt6ct";
  };

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
      isLightMode = false;
      dynamicTheming = true;
      use24HourClock = false;
      matugenTargetMonitor = "eDP-1";
      currentThemeCategory = "dynamic";
      cursorSettings = {
        theme = "Adwaita";
        size = 24;

      };
      gtkThemingEnabled = true;
      qtThemingEnabled = true;
      runDmsMatugenTemplates = true;
      matugenTemplateGtk = true;
      matugenTemplateQt5ct = true;
      matugenTemplateQt6ct = true;

    };
    session = {
      wallpaperPath = "${userConfig.homeDirectory}/Pictures/wallpapers/1351306.png";
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

    # nix flake show github:AvengeMedia/dms-plugin-registry
    plugins = {
      dankBatteryAlerts = {
        enable = true;
        src = inputs.dms-plugin-registry.packages.${pkgs.stdenv.hostPlatform.system}.dankBatteryAlerts;
      };
      dockerManager.enable = false;

      # plugin-specific settings
      mediaPlayer = {
        enable = true;
        src = inputs.dms-plugin-registry.packages.${pkgs.stdenv.hostPlatform.system}.mediaPlayer;
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
          "cursor"
          "layout"
          "outputs"
          "windowrules"
        ];
      };

    };
  };

  services.gnome-keyring.enable = true;

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
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

  home.packages = with pkgs; [
    thunar
    adw-gtk3
    adwaita-qt
    adwaita-qt6
    qt6ct-kde
    qadwaitadecorations
    qadwaitadecorations-qt6
    libsForQt5.qt5ct
    libsForQt5.qtstyleplugins
    klassy
  ];

}
