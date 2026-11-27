{ qt6ctKdeAur, kdl }:
{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixConfig.desktop.niri;
  inherit (config.nixConfig) displays;
  connectors = internal: builtins.attrNames (lib.filterAttrs (_: d: d.internal == internal) displays);
  internals = connectors true;
  externals = connectors false;

  # Taken from DMS's generated binds.kdl, minus the entries that call the shell.
  genericBinds =
    let
      a = config.lib.niri.actions;
      bind = action: { inherit action; };
      # The same action on an arrow key and its vim key.
      directional =
        prefix: actions:
        lib.concatMapAttrs (dir: action: {
          "${prefix}${dir}" = bind action;
          "${prefix}${vimKeys.${dir}}" = bind action;
        }) actions;
      vimKeys = {
        Left = "H";
        Down = "J";
        Up = "K";
        Right = "L";
      };
      workspaces = lib.mergeAttrsList (
        map (n: {
          "Mod+${toString n}" = bind (a.focus-workspace n);
          # Not in niri-flake's memoised action list, so set as a plain attribute.
          "Mod+Shift+${toString n}".action.move-column-to-workspace = n;
        }) (lib.range 1 9)
      );
      terminal = {
        action = a.spawn "ghostty";
        hotkey-overlay.title = "Open Terminal";
      };
      wheel = action: {
        inherit action;
        cooldown-ms = 150;
      };
    in
    directional "Mod+" {
      Left = a.focus-column-left;
      Down = a.focus-window-down;
      Up = a.focus-window-up;
      Right = a.focus-column-right;
    }
    // directional "Mod+Shift+" {
      Left = a.move-column-left;
      Down = a.move-window-down;
      Up = a.move-window-up;
      Right = a.move-column-right;
    }
    // directional "Mod+Ctrl+" {
      Left = a.focus-monitor-left;
      Down = a.focus-monitor-down;
      Up = a.focus-monitor-up;
      Right = a.focus-monitor-right;
    }
    // directional "Mod+Shift+Ctrl+" {
      Left = a.move-column-to-monitor-left;
      Down = a.move-column-to-monitor-down;
      Up = a.move-column-to-monitor-up;
      Right = a.move-column-to-monitor-right;
    }
    // workspaces
    // {
      # Override the arrow half of Mod+Ctrl above: monitors are usually side by side, so the
      # vertical arrows move the column between workspaces instead (as in DMS).
      "Mod+Ctrl+Down" = bind a.move-column-to-workspace-down;
      "Mod+Ctrl+Up" = bind a.move-column-to-workspace-up;
      "Mod+Shift+Space" = {
        action.switch-layout = "next";
        hotkey-overlay.title = "Switch Keyboard Layout";
      };
      "Mod+O" = bind a.toggle-overview // {
        repeat = false;
      };
      "Mod+Tab" = bind a.toggle-overview // {
        repeat = false;
      };
      "Mod+T" = terminal;
      "Mod+Return" = terminal;
      "Mod+Shift+E" = bind a.quit;
      "Mod+Shift+P" = bind a.power-off-monitors;
      "Mod+Escape" = bind a.toggle-keyboard-shortcuts-inhibit // {
        allow-inhibiting = false;
      };

      "Mod+Q" = bind a.close-window // {
        repeat = false;
      };
      "Alt+F4" = bind a.close-window // {
        repeat = false;
      };
      "Mod+F" = bind a.maximize-column;
      "Mod+Shift+F" = bind a.fullscreen-window;
      "Mod+Shift+T" = bind a.toggle-window-floating;
      "Mod+Shift+V" = bind a.switch-focus-between-floating-and-tiling;
      "Mod+W" = bind a.toggle-column-tabbed-display;

      "Mod+Home" = bind a.focus-column-first;
      "Mod+End" = bind a.focus-column-last;
      "Mod+Ctrl+Home" = bind a.move-column-to-first;
      "Mod+Ctrl+End" = bind a.move-column-to-last;

      "Mod+Page_Down" = bind a.focus-workspace-down;
      "Mod+Page_Up" = bind a.focus-workspace-up;
      "Mod+U" = bind a.focus-workspace-down;
      "Mod+I" = bind a.focus-workspace-up;
      "Mod+Ctrl+U" = bind a.move-column-to-workspace-down;
      "Mod+Ctrl+I" = bind a.move-column-to-workspace-up;
      "Mod+Shift+Page_Down" = bind a.move-workspace-down;
      "Mod+Shift+Page_Up" = bind a.move-workspace-up;
      "Mod+Shift+U" = bind a.move-workspace-down;
      "Mod+Shift+I" = bind a.move-workspace-up;

      "Mod+WheelScrollDown" = wheel a.focus-workspace-down;
      "Mod+WheelScrollUp" = wheel a.focus-workspace-up;
      "Mod+Ctrl+WheelScrollDown" = wheel a.move-column-to-workspace-down;
      "Mod+Ctrl+WheelScrollUp" = wheel a.move-column-to-workspace-up;
      "Mod+WheelScrollRight" = bind a.focus-column-right;
      "Mod+WheelScrollLeft" = bind a.focus-column-left;
      "Mod+Ctrl+WheelScrollRight" = bind a.move-column-right;
      "Mod+Ctrl+WheelScrollLeft" = bind a.move-column-left;
      "Mod+Shift+WheelScrollDown" = bind a.focus-column-right;
      "Mod+Shift+WheelScrollUp" = bind a.focus-column-left;
      "Mod+Ctrl+Shift+WheelScrollDown" = bind a.move-column-right;
      "Mod+Ctrl+Shift+WheelScrollUp" = bind a.move-column-left;

      "Mod+BracketLeft" = bind a.consume-or-expel-window-left;
      "Mod+BracketRight" = bind a.consume-or-expel-window-right;
      "Mod+Period" = bind a.expel-window-from-column;

      "Mod+R" = bind a.switch-preset-column-width;
      "Mod+Shift+R" = bind a.switch-preset-window-height;
      "Mod+Ctrl+R" = bind a.reset-window-height;
      "Mod+Ctrl+F" = bind a.expand-column-to-available-width;
      "Mod+C" = bind a.center-column;
      "Mod+Ctrl+C" = bind a.center-visible-columns;
      "Mod+Minus" = bind (a.set-column-width "-10%");
      "Mod+Equal" = bind (a.set-column-width "+10%");
      "Mod+Shift+Minus" = bind (a.set-window-height "-10%");
      "Mod+Shift+Equal" = bind (a.set-window-height "+10%");
    };

  # nixpkgs' qt6ct + the AUR qt6ct-kde patch. The AUR repo is a flake input,
  # so `nix flake update` bumps it; if the patch stops applying, the build fails before switching.
  qt6ct-kde = pkgs.kdePackages.qt6ct.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [ "${qt6ctKdeAur}/qt6ct-shenanigans.patch" ];
    buildInputs = oldAttrs.buildInputs ++ [ pkgs.kdePackages.qqc2-desktop-style ];
  });
in
{
  options.nixConfig.desktop.niri = {
    enable = lib.mkEnableOption "the niri session";

    # Set by the shell module (home/desktop/dms.nix): the files its theme generator writes from
    # the wallpaper, which GTK and Qt apps below load to follow its colours.
    palette = {
      gtkCss = lib.mkOption {
        type = lib.types.str;
        description = "File name of the shell-generated GTK stylesheet in gtk-3.0/ and gtk-4.0/.";
      };
      kdeColorScheme = lib.mkOption {
        type = lib.types.str;
        description = "Name (without .colors) of the shell-generated scheme in $XDG_DATA_HOME/color-schemes.";
      };
    };

    # For what programs.niri.settings has no options for (recent-windows, include). Appended after
    # the rendered settings, so it overrides them (niri includes are positional).
    extraConfig = lib.mkOption {
      type = kdl.types.kdl-document;
      default = [ ];
      description = "KDL nodes appended to the niri config generated from programs.niri.settings.";
    };
  };

  config = lib.mkIf cfg.enable {
    # The rest of this desktop; each can still be switched off individually.
    nixConfig.desktop = {
      common.enable = lib.mkDefault true;
      dms.enable = lib.mkDefault true;
    };

    services.gnome-keyring.enable = true;
    home.packages = with pkgs; [
      gcr_4

      # Desktop apps GNOME used to provide (image viewer: nomacs, in users/ahmed/asus-laptop/default.nix).
      nautilus # file manager + portal file chooser (programs.niri.useNautilus in nixos/desktop/niri.nix)
      file-roller # archives; Nautilus "Extract"/"Compress"
      papers # PDF viewer (also its own PDF thumbnailer)
      glycin-thumbnailer # image thumbnails (same picks as the nixpkgs GNOME module)
      gst-thumbnailers # audio/video thumbnails
      libnotify # notify-send: shell notification previews and scripts

      adw-gtk3
      # Qt client-side decorations (QT_WAYLAND_DECORATION below); qt6ct-kde comes from qt.platformTheme.
      qadwaitadecorations
      qadwaitadecorations-qt6
      kdePackages.breeze # Qt style (qt.qt6ctSettings.Appearance.style)
      nirimod
      xwayland-satellite
      gnome-tecla
      gnome-calculator
    ];

    # GTK apps follow the shell's wallpaper colours: gtk.css imports the stylesheet the shell
    # generates (cfg.palette). Restart a running GTK app to see new colours.
    # The theme below is only the login default; no prefer-dark-theme key, since it would pin
    # GTK3 to dark while the shell switches dark/light at runtime.
    gtk =
      let
        paletteImport = ''@import url("${cfg.palette.gtkCss}");'';
      in
      {
        enable = true;
        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };
        gtk3.extraCss = paletteImport;
        gtk4 = {
          theme = null;
          # libadwaita >= 1.6 widgets read --accent-* vars, which its stylesheet binds to the
          # system accent preset (gsettings accent-color, e.g. blue), ignoring our @define-color.
          # Rebinding them here (user priority) makes accents follow the shell palette.
          extraCss = ''
            ${paletteImport}
            :root {
              --accent-color: @accent_color;
              --accent-bg-color: @accent_bg_color;
              --accent-fg-color: @accent_fg_color;
            }
          '';
        };
      };

    # Qt apps follow the shell's wallpaper colours through qt6ct-kde: the shell writes a KDE colour
    # scheme (cfg.palette; KDE format needs the kde patch) and qt6ct.conf points at it.
    # enable = true also exports QT_PLUGIN_PATH (profile plugins), without which libqt6ct.so is never found.
    # Colours load at app start; restart a running Qt app to see a new palette.
    qt = {
      enable = true;
      platformTheme = {
        name = "qt6ct";
        package = qt6ct-kde; # replaces stock qt6ct (same plugin file, would collide)
      };
      qt6ctSettings.Appearance = {
        style = "Breeze"; # KDE style, honors KDE color schemes; built-in alternative: "Fusion" (plainer)
        custom_palette = true;
        color_scheme_path = "${config.xdg.dataHome}/color-schemes/${cfg.palette.kdeColorScheme}.colors";
        icon_theme = "Adwaita"; # same as GTK
        standard_dialogs = "xdgdesktopportal"; # Nautilus file chooser
      };
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

    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    # Written to ~/.config/environment.d, read by the systemd user manager at login.
    # greetd's login doesn't export XDG_SESSION_CLASS (GDM did), and localsearch-3.service has
    # ConditionEnvironment=XDG_SESSION_CLASS=user, so without this the indexer never starts.
    systemd.user.sessionVariables.XDG_SESSION_CLASS = "user";

    programs.niri = {
      enable = true;
      package = pkgs.niri;
      settings = {
        # xwayland-satellite: niri (>= 25.08) spawns it on demand; it only needs to be in PATH as a package
        input = {
          focus-follows-mouse = {
            enable = true;
            max-scroll-amount = "60%";
          };

          keyboard = {
            numlock = true;
            # English + Arabic; switch with Mod+Shift+Space (bind below) or click the DMS bar widget.
            # Not an xkb grp:* toggle: Alt+Shift would also fire on Alt+Shift+Arrow (window moves).
            #
            # Names come from xkeyboard-config (a libxkbcommon dependency, pinned via nixpkgs).
            # `localectl list-x11-keymap-*` doesn't work on NixOS (no /etc/X11/xkb); read the list directly:
            #   X=$(nix build nixpkgs#xkeyboard-config --print-out-paths --no-link)/share/X11/xkb/rules/evdev.lst
            #   awk '/^! layout/{f=1;next} /^!/{f=0} f' $X | less                # all layouts
            #   awk '/^! variant/{f=1;next} /^!/{f=0} f && $2=="ara:"' $X        # variants of one layout
            # Preview on a drawn keyboard (layout or layout+variant):
            #   nix run nixpkgs#gnome-tecla -- ara
            #   nix run nixpkgs#gnome-tecla -- ara+mac
            # Arabic variants: basic (default when empty: standard QWERTY-based/Windows Arabic, what
            # Arabic-printed laptop keys use; Q=ض A=ش Z=ئ), digits, azerty (French-keyboard base),
            # azerty_digits, buckwalter, mac, mac-phonetic, olpc. Source: symbols/ara in the same package.
            xkb = {
              layout = "us,ara";
              # One entry per layout, by position; "" = the layout's default (its "basic" section).
              variant = ",basic";
            };
          };
        };
        layout = {
          # Outer gaps in logical px. Left/right struts make the neighbouring column peek into them;
          # left is sized to the DMS dock (iconSize 36 + padding) so the peek isn't hidden behind it.
          struts = {
            left = 1;
            right = 1;
            top = 0;
            bottom = 0;
          };
          # DMS takes this as niriLayoutGapsOverride (home/desktop/dms.nix).
          gaps = 8;
          focus-ring.width = 2;
        };
        # DMS takes these as cursorSettings (home/desktop/dms.nix).
        cursor = {
          theme = "Adwaita";
          size = 32;
          hide-when-typing = true;
          hide-after-inactive-ms = 2000;
        };
        window-rules = [
          {
            geometry-corner-radius =
              let
                r = 8.0;
              in
              {
                top-left = r;
                top-right = r;
                bottom-right = r;
                bottom-left = r;
              };
            clip-to-geometry = true;
            # Windows draw square corners and no client-side shadows, as when tiled.
            tiled-state = true;
            draw-border-with-background = false;
          }
        ];
        # Shell-independent binds; each shell module adds its own (launcher, media keys, lock, …).
        # Under DMS, its generated binds.kdl is included after these and wins on shared keys.
        binds = genericBinds;
        # Generated from nixConfig.displays (hosts/<host>/displays.nix via registry.nix).
        # To let DMS manage monitors instead (Settings → Displays + profiles):
        # remove this line and services.kanshi below, uncomment "outputs" in home/desktop/dms.nix,
        # and set programs.dank-material-shell.settings.displayProfileAutoSelect = true.
        outputs = lib.mapAttrs (
          _: d:
          {
            mode = { inherit (d) width height refresh; };
            position = { inherit (d) x y; };
          }
          // lib.optionalAttrs (d.scale != null) { inherit (d) scale; }
        ) displays;

        # QT_QPA_PLATFORMTHEME comes from the qt block above.
        environment = {
          QT_WAYLAND_DECORATION = "adwaita";

          # Make Electron/Chromium autodetect gnome-libsecret without per-app argv.json or
          # wrappers. Covers everything niri spawns: Antigravity, VS Code, Slack, Vesktop,
          # Signal, 1Password, misterdownloadmanager, …
          # Keep the "niri:" prefix so niri-aware tooling (portals, DMS) still matches;
          # don't set bare "GNOME" — that activates GNOME-isms in some libadwaita apps.
          XDG_CURRENT_DESKTOP = "niri:GNOME";
        };
      };
      # Setting `config` replaces its default (the rendered settings), so render them here too.
      # Under DMS this whole document becomes niri/hm.kdl, which DMS includes first.
      config = options.programs.niri.config.default ++ cfg.extraConfig;
    };

    nixConfig.desktop.niri.extraConfig = [
      (kdl.plain "recent-windows" [
        # Larger Alt-Tab previews: niri's switcher has no app icons, so make contents readable.
        # max-scale is relative (also caps height at monitor height × 0.75).
        # max-height is absolute (logical px) and only lifts niri's default of 480; 1080 = 0.75 × 1440p.
        # niri defaults (to revert): max-height 480, max-scale 0.5 — or delete this previews block.
        (kdl.plain "previews" [
          (kdl.leaf "max-height" 1080)
          (kdl.leaf "max-scale" 0.75)
        ])
      ])
    ];

    # Runtime output profiles, picked by which monitors are connected (exact set match).
    # docked: every external connected → internal panels off. mobile: internals only.
    # Only toggles internals; modes/positions stay in programs.niri.settings.outputs above.
    # Enabled only on hosts that have both internal and external displays.
    # Session-only: the greeter is a separate niri instance, so the panel stays on at login.
    # Remove when using DMS display profiles (see the outputs comment above); never run both.
    services.kanshi = {
      enable = internals != [ ] && externals != [ ];
      settings = [
        {
          profile.name = "docked";
          profile.outputs =
            map (criteria: { inherit criteria; }) externals
            ++ map (criteria: {
              inherit criteria;
              status = "disable";
            }) internals;
        }
        {
          # Without this, unplugging the externals would leave the panel disabled (black screen).
          profile.name = "mobile";
          profile.outputs = map (criteria: {
            inherit criteria;
            status = "enable";
          }) internals;
        }
      ];
    };
  };
}
