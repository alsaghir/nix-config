{
  config,
  lib,
  pkgs,
  userConfig,
  ...
}:

let
  preferDark = userConfig.preferences.theme == "dark";
in
{
  programs.konsole.enable = true;

  programs.plasma = {
    enable = true;

    kwin = {
      virtualDesktops.rows = 1;
      effects.desktopSwitching.navigationWrapping = true;
    };

    workspace = {
      theme = "breeze-dark";
      colorScheme = "BreezeDark";
      iconTheme = "breeze-dark";

      cursor = {
        theme = "breeze_cursors";
      };
      windowDecorations = {
        library = "org.kde.klassy";
        theme = "Klassy";
      };

      wallpaperSlideShow = {
        path = [
          "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/"
          "${userConfig.homeDirectory}/Pictures/wallpapers/"
        ];
        interval = 300;
      };
    };

    panels = [
      {
        location = "top";
        lengthMode = "fit";

        # https://nix-community.github.io/plasma-manager/options.xhtml#opt-programs.plasma.panels._.widgets
        widgets = [
          { kickerdash = { }; }
          {
            pager = {
              general = {
                showApplicationIconsOnWindowOutlines = true; # This sets showWindowIcons=true
                navigationWrapsAround = true; # This sets wrapPage=true
              };
            };
          }

          { iconTasks = { }; }

          "org.kde.plasma.marginsseparator"

          { systemTray = { }; }

          {
            digitalClock = {
              time.format = "12h";
            };
          }
          "org.kde.plasma.showdesktop"
        ];
      }
    ];

    input.keyboard = {
      layouts = [
        {
          layout = "us";
        }
        {
          layout = "eg";
        }
      ];
      repeatDelay = 300;
      numlockOnStartup = "on";
    };

    powerdevil.AC = {
      autoSuspend = {
        idleTimeout = 900;
      };

      dimDisplay = {
        enable = true;
        idleTimeout = 600;
      };
      turnOffDisplay = {
        idleTimeoutWhenLocked = 120;
        idleTimeout = 900;
      };
    };

    shortcuts = {
      kwin = {
        "Window Maximize" = [
          "Meta+F"
          "Maximize Window"
        ];
      };
    };

    configFile = {
      kwinrc = {
        Plugins.desktopchangeosdEnabled = true;
        Plugins.dynamic_workspacesEnabled = true;
        Plugins.krohnkiteEnabled = true;

        "Effect-slide" = {
          SlideBackground = false;
        };

        Script-krohnkite = {
          monocleMaximize = false;

          screenGapBetween = 6;
          screenGapBottom = 6;
          screenGapLeft = 6;
          screenGapRight = 6;
          screenGapTop = 6;

          stairLayoutOrder = 1;
          spreadLayoutOrder = 2;
          binaryTreeLayoutOrder = 3;
          tileLayoutOrder = 4;
          monocleLayoutOrder = 5;
          threeColumnLayoutOrder = 6;
          spiralLayoutOrder = 7;
          quarterLayoutOrder = 8;
          stackedLayoutOrder = 9;
          columnsLayoutOrder = 10;
          floatingLayoutOrder = 11;

        };

        Windows = {
          FocusPolicy = "FocusFollowsMouse";
          PerOutputVirtualDesktops = true;
        };

      };

      kdeglobals = {
        KDE = {
          AnimationDurationFactor = 0.5;
        };
        General = {
          accentColorFromWallpaper = true;
        };
        WM = {
          frame = "61,174,233";
          inactiveFrame = "239,240,241";
        };

      };

      "klassy/klassyrc" = {
        WindowOutlineStyle = {
          WindowOutlineCustomColorActive = "61,174,233";
          WindowOutlineCustomColorInactive = "239,240,241";
          WindowOutlineStyleActive = "WindowOutlineAccentColor"; # or "WindowOutlineCustomColor"
          WindowOutlineThickness = 4.0;
        };
      };

    };

  };

  services.kdeconnect.enable = true;

  programs.firefox.package = pkgs.firefox.override {
    cfg = {
      enablePlasmaBrowserIntegration = true;
    };
  };

  programs.firefox.nativeMessagingHosts = [
    pkgs.firefoxpwa
    pkgs.kdePackages.plasma-browser-integration
  ];

  home.packages = with pkgs; [
    kdePackages.dynamic-workspaces
    kdePackages.krohnkite

    kdePackages.dolphin
    kdePackages.dolphin-plugins
    kdePackages.ark
    kdePackages.kcolorchooser
    kdePackages.filelight
    kdePackages.spectacle
    kdePackages.kcharselect
    kdePackages.kwallet
    kdePackages.kwalletmanager
    kdePackages.plasma-systemmonitor
    kdePackages.kmail
    kdePackages.kmail-account-wizard
    kdePackages.plasma-browser-integration

    # System settings and theming
    kdePackages.kde-gtk-config
    kdePackages.breeze-gtk

    # Qt theming
    kdePackages.qtstyleplugin-kvantum
    klassy

    kdePackages.gwenview

    # Media codecs
    ffmpeg-headless
    ffmpegthumbnailer
    gst_all_1.gst-libav
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-vaapi
    gst_all_1.gstreamer

    adwaita-fonts
    imagemagick
    wl-clipboard
  ];

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  gtk = {
    enable = true;
    theme = {
      name = if preferDark then "Breeze-Dark" else "Breeze";
      package = pkgs.kdePackages.breeze-gtk;
    };
    gtk2.force = true;
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = if preferDark then 1 else 0;
    };
    gtk4 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = if preferDark then 1 else 0;
      };
      theme = null;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "breeze";
  };
}
