# KDE Plasma 6 session settings via plasma-manager (system side: nixos/desktop/plasma.nix).
#
# plasma-manager writes only the keys declared here (overrideConfig stays false), so settings
# changed in System Settings survive unless they are also set below.
# Apps shipped by the NixOS plasma6 module (Dolphin, Okular, Konsole, Spectacle, Ark, Gwenview,
# KWalletManager, plasma-browser-integration, kde-gtk-config, breeze-gtk) are not repeated here.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.nixConfig.desktop.plasma.enable = lib.mkEnableOption "the KDE Plasma 6 session settings";

  config = lib.mkIf config.nixConfig.desktop.plasma.enable {
    nixConfig.desktop.common.enable = lib.mkDefault true;

    # kde-gtk-config rewrites gtk-{3,4}.0/settings.ini and ~/.gtkrc-2.0 from Plasma's settings;
    # Home Manager's read-only copies of those files would break that sync. Explicit so that
    # enabling niri (which sets it true) alongside Plasma fails evaluation instead.
    gtk.enable = false;

    home.sessionVariables.NIXOS_OZONE_WL = "1";

    programs.firefox.nativeMessagingHosts = [ pkgs.kdePackages.plasma-browser-integration ];

    xdg.mimeApps.defaultApplications = {
      # VS Code also claims folders.
      "inode/directory" = "org.kde.dolphin.desktop";
      "application/pdf" = "okularApplication_pdf.desktop";
    };

    home.packages = with pkgs; [
      kdePackages.krohnkite
      kdePackages.dynamic-workspaces
      klassy
      kdePackages.kcolorchooser
      kdePackages.filelight
      kdePackages.kcharselect
      wl-clipboard
    ];

    programs.plasma = {
      enable = true;

      workspace = {
        theme = "breeze-dark";
        colorScheme = "BreezeDark";
        iconTheme = "breeze-dark";
        cursor.theme = "breeze_cursors";
        windowDecorations = {
          library = "org.kde.klassy";
          theme = "Klassy";
        };
        wallpaperSlideShow = {
          path = [
            "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/"
            "${config.home.homeDirectory}/Pictures/wallpapers/"
          ];
          interval = 300;
        };
      };

      kwin = {
        virtualDesktops.rows = 1;
        effects.desktopSwitching.navigationWrapping = true;
      };

      panels = [
        {
          location = "top";
          lengthMode = "fit";
          # https://nix-community.github.io/plasma-manager/options.xhtml#opt-programs.plasma.panels._.widgets
          widgets = [
            { kickerdash = { }; }
            {
              pager.general = {
                showApplicationIconsOnWindowOutlines = true;
                navigationWrapsAround = true;
              };
            }
            { iconTasks = { }; }
            "org.kde.plasma.marginsseparator"
            { systemTray = { }; }
            { digitalClock.time.format = "12h"; }
            "org.kde.plasma.showdesktop"
          ];
        }
      ];

      # Same layouts as niri (home/desktop/niri.nix has the notes on picking xkb names).
      input.keyboard = {
        layouts = [
          { layout = "us"; }
          {
            layout = "ara";
            variant = "basic";
          }
        ];
        repeatDelay = 300;
        numlockOnStartup = "on";
      };

      powerdevil.AC = {
        autoSuspend.idleTimeout = 900;
        dimDisplay = {
          enable = true;
          idleTimeout = 600;
        };
        turnOffDisplay = {
          idleTimeout = 900;
          idleTimeoutWhenLocked = 120;
        };
      };

      shortcuts = {
        # Same key as niri; an xkb grp:* toggle would also fire on Alt+Shift+Arrow.
        # Component/action names from kwin's src/keyboard_layout.cpp.
        "KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" = "Meta+Shift+Space";

        kwin = {
          "Window Maximize" = "Meta+F";
          "MoveMouseToCenter" = "Meta+F6";
          "MoveMouseToFocus" = "Meta+F5";
          "Window to Next Screen" = "Meta+Shift+Right";
          "Window to Previous Screen" = "Meta+Shift+Left";
          "Window One Desktop Down" = "Meta+Ctrl+Shift+Down";
          "Window One Desktop Up" = "Meta+Ctrl+Shift+Up";
          "Window One Desktop to the Left" = "Meta+Ctrl+Shift+Left";
          "Window One Desktop to the Right" = "Meta+Ctrl+Shift+Right";
          "Switch to Next Screen" = "Meta+]";
          "Switch to Previous Screen" = "Meta+[";

          "KrohnkiteFocusNext" = "Meta+Ctrl+L";
          "KrohnkiteFocusPrev" = "Meta+Ctrl+H";
          "KrohnkiteNextLayout" = "Meta+\\";
          "KrohnkitePreviousLayout" = "Meta+|";
          "KrohnkiteToggleFloat" = "Meta+Alt+Esc";
          "KrohnkiteShiftLeft" = "Meta+Shift+H";
          "KrohnkiteShiftRight" = "Meta+Shift+L";
        };
      };

      configFile = {
        kwinrc = {
          Plugins = {
            desktopchangeosdEnabled = true;
            dynamic_workspacesEnabled = true;
            krohnkiteEnabled = true;
          };

          "Effect-slide".SlideBackground = false;

          Script-krohnkite = {
            monocleMaximize = false;

            screenGapBetween = 6;
            screenGapBottom = 6;
            screenGapLeft = 6;
            screenGapRight = 6;
            screenGapTop = 6;

            # Cycle order for Krohnkite(Next|Previous)Layout.
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
          KDE.AnimationDurationFactor = 0.5;
          General.accentColorFromWallpaper = true;
          WM = {
            frame = "61,174,233";
            inactiveFrame = "239,240,241";
          };
        };

        "klassy/klassyrc".WindowOutlineStyle = {
          WindowOutlineCustomColorActive = "61,174,233";
          WindowOutlineCustomColorInactive = "239,240,241";
          WindowOutlineStyleActive = "WindowOutlineAccentColor";
          WindowOutlineThickness = 4.0;
        };
      };
    };
  };
}
