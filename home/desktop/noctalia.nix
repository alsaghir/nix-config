# Noctalia shell (bar, dock, launcher, notifications, lock screen, idle) for the niri session;
# chosen by nixConfig.desktop.niri.shell. GUI changes go to ~/.local/state/noctalia/settings.toml
# and override the config.toml written here. Key reference:
# https://docs.noctalia.dev/noctalia/configuration/
#
# Started by niri (spawn-at-startup), not Noctalia's systemd unit: that one binds to
# graphical-session.target and would also start inside Plasma.
{ kdl }:
{ config, lib, ... }:
let
  prefs = import ./shell-preferences.nix;
  home = config.home.homeDirectory;

  msg = args: {
    action.spawn = [
      "noctalia"
      "msg"
    ]
    ++ args;
  };
  titled = title: bind: bind // { hotkey-overlay.title = title; };
  whenLocked = bind: bind // { allow-when-locked = true; };
in
{
  options.nixConfig.desktop.noctalia.enable =
    lib.mkEnableOption "the Noctalia shell (bar, launcher, notifications)";

  config = lib.mkIf config.nixConfig.desktop.noctalia.enable {
    # Builtin templates below write these from the wallpaper palette.
    nixConfig.desktop.niri = {
      palette = {
        gtkCss = "noctalia.css";
        kdeColorScheme = "noctalia";
      };
      # Written by the niri template (focus-ring, border and switcher colours). Last, so its
      # colours win; optional, since it only exists after Noctalia's first run. The template's
      # apply.sh sees this include and leaves the read-only config.kdl alone.
      extraConfig = lib.mkAfter [
        (kdl.leaf "include" [
          { optional = true; }
          "noctalia.kdl"
        ])
      ];
    };

    programs.noctalia = {
      enable = true;
      settings = {
        shell = {
          font_family = prefs.fontFamily;
          time_format = if prefs.clock12h then "{:%I:%M %p}" else "{:%H:%M}";
        };

        theme = {
          mode = "dark";
          source = "wallpaper";
          templates = {
            enable_builtin_templates = true;
            builtin_ids = [
              "gtk3"
              "gtk4"
              "kcolorscheme"
              "niri"
            ];
          };
        };

        wallpaper = {
          directory = "${home}/${dirOf prefs.wallpaper.default}";
          default.path = "${home}/${prefs.wallpaper.default}";
          automation = {
            enabled = true;
            interval_seconds = prefs.wallpaper.cycleSeconds;
          };
          transition = [
            "fade"
            "wipe"
            "disc"
            "stripes"
            "pixel"
          ];
        };

        weather.enabled = true;
        location = {
          latitude = builtins.fromJSON prefs.location.latitude;
          longitude = builtins.fromJSON prefs.location.longitude;
        };

        # Noctalia has one idle profile; the AC one is used (DMS also has a battery profile).
        idle = {
          behavior_order = [
            "lock"
            "screen-off"
            "suspend"
          ];
          behavior = {
            lock = {
              action = "lock";
              timeout = prefs.idle.ac.lock;
            };
            screen-off = {
              action = "screen_off";
              timeout = prefs.idle.ac.screenOff;
              locked_timeout = prefs.idle.ac.screenOffLocked;
            };
            suspend = {
              action = "lock_and_suspend";
              timeout = prefs.idle.ac.suspend;
            };
          };
        };

        # Lists replace Noctalia's stock ones, so they restate its defaults (example.toml) plus the
        # additions: running apps, and the current layout (EN/AR) before notifications.
        bar.main = {
          inherit (prefs.bar) position padding;
          background_opacity = prefs.bar.opacity;
          font_scale = prefs.bar.fontScale;
          capsule = true;
          capsule_border = "secondary";
          capsule_border_width = prefs.bar.outlineThickness;
          start = [
            "launcher"
            "wallpaper"
            "workspaces"
            "taskbar"
          ];
          center = [ "clock" ];
          end = [
            "media"
            "tray"
            "keyboard_layout"
            "notifications"
            "clipboard"
            "network"
            "bluetooth"
            "volume"
            "brightness"
            "battery"
            "control-center"
            "session"
          ];
        };

        dock = {
          enabled = true;
          inherit (prefs.dock) position pinned;
          icon_size = prefs.dock.iconSize;
          item_spacing = prefs.dock.itemSpacing;
        };
      };
    };

    programs.niri.settings = {
      spawn-at-startup = [ { argv = [ "noctalia" ]; } ];

      # From Noctalia's niri guide: its settings window floats, and it activates its own windows
      # with serials niri would otherwise reject.
      window-rules = [
        {
          matches = [ { app-id = "^dev\\.noctalia\\.Noctalia$"; } ];
          open-floating = true;
          default-column-width.fixed = 1080;
          default-window-height.fixed = 920;
        }
      ];
      debug.honor-xdg-activation-with-invalid-serial = [ ];

      # Same keys as DMS's binds.kdl; Alt+Tab stays niri's own switcher (recent-windows), as under DMS.
      binds = {
        "Mod+Shift+Slash" = {
          action.show-hotkey-overlay = [ ];
        };
        "Mod+Space" = titled "Application Launcher" (msg [
          "panel-toggle"
          "launcher"
        ]);
        "Mod+V" = titled "Clipboard Manager" (msg [
          "panel-toggle"
          "clipboard"
        ]);
        "Mod+M" = titled "Media" (msg [
          "panel-toggle"
          "control-center"
          "media"
        ]);
        "Mod+X" = titled "Session Menu" (msg [
          "panel-toggle"
          "session"
        ]);
        "Mod+A" = titled "Control Center" (msg [
          "panel-toggle"
          "control-center"
        ]);
        "Mod+Ctrl+N" = titled "Notification Center" (msg [
          "panel-toggle"
          "control-center"
          "notifications"
        ]);
        "Mod+Y" = titled "Browse Wallpapers" (msg [
          "panel-toggle"
          "wallpaper"
        ]);
        "Mod+Comma" = titled "Settings" (msg [ "settings-toggle" ]);
        "Mod+Alt+N" = titled "Night Light" (msg [ "nightlight-force-toggle" ]);
        "Mod+Alt+I" = titled "Idle Inhibit" (msg [ "caffeine-toggle" ]);
        "Mod+Alt+L" = titled "Lock Screen" (msg [
          "session"
          "lock"
        ]);

        "XF86AudioRaiseVolume" = whenLocked (msg [ "volume-up" ]);
        "XF86AudioLowerVolume" = whenLocked (msg [ "volume-down" ]);
        "XF86AudioMute" = whenLocked (msg [ "volume-mute" ]);
        "XF86AudioMicMute" = whenLocked (msg [ "mic-mute" ]);
        "XF86AudioPlay" = whenLocked (msg [
          "media"
          "toggle"
        ]);
        "XF86AudioPause" = whenLocked (msg [
          "media"
          "toggle"
        ]);
        "XF86AudioPrev" = whenLocked (msg [
          "media"
          "previous"
        ]);
        "XF86AudioNext" = whenLocked (msg [
          "media"
          "next"
        ]);
        "Ctrl+XF86AudioRaiseVolume" = whenLocked (msg [
          "media"
          "volume-up"
        ]);
        "Ctrl+XF86AudioLowerVolume" = whenLocked (msg [
          "media"
          "volume-down"
        ]);
        "XF86MonBrightnessUp" = whenLocked (msg [ "brightness-up" ]);
        "XF86MonBrightnessDown" = whenLocked (msg [ "brightness-down" ]);
      }
      # XF86Launch1 is the laptop's screenshot key. Noctalia 5.5 has no window capture, so that
      # one is niri's.
      // lib.concatMapAttrs (_: key: {
        ${key} = titled "Screenshot: Region" (msg [ "screenshot-region" ]);
        "Ctrl+${key}" = titled "Screenshot: Full Screen" (msg [ "screenshot-fullscreen" ]);
        "Alt+${key}" = titled "Screenshot: Window" { action.screenshot-window = [ ]; };
      }) (lib.genAttrs [ "Print" "XF86Launch1" ] lib.id);
    };
  };
}
