{
  config,
  pkgs,
  lib,
  ...
}:

let

  theme = if config.myTheme.preferDark then "adwaita-dark" else "adwaita";
  gtkTheme = if config.myTheme.preferDark then "Adwaita-dark" else "Adwaita";
  gtkThemeEnv = if config.myTheme.preferDark then "Adwaita:dark" else "Adwaita";

  # System-level override of Nemo's desktop entry (same filename: nemo.desktop)
  nemoDesktopOverride = pkgs.runCommand "nemo-desktop-override" { meta.priority = 1; } ''
    set -euo pipefail
    mkdir -p "$out/share/applications"
    cp ${pkgs.nemo-with-extensions}/share/applications/nemo.desktop "$out/share/applications/nemo.desktop"
    chmod u+w "$out/share/applications/nemo.desktop"

    # Patch Exec to enforce GTK_THEME and adjust fields to make search find "Nemo"
    sed -i \
      -e 's|^Exec=.*|Exec=env GTK_THEME=${gtkThemeEnv} ${pkgs.nemo-with-extensions}/bin/nemo %U|' \
      -e 's|^Categories=.*|Categories=System;Utility;FileManager;GTK;|' \
      -e 's|^MimeType=.*|MimeType=inode/directory;application/x-gnome-saved-search;inode/file;x-scheme-handler/file;|' \
      -e 's|^Name=.*|Name=Nemo|' \
      "$out/share/applications/nemo.desktop"

    # Ensure DBusActivatable=false (remove any existing, then append)
    sed -i '/^DBusActivatable=/d' "$out/share/applications/nemo.desktop"
    printf '\nDBusActivatable=false\n' >> "$out/share/applications/nemo.desktop"

    # Ensure Keywords include Nemo for GNOME search
    if ! grep -q '^Keywords=' "$out/share/applications/nemo.desktop"; then
      printf 'Keywords=Nemo;File;Files;File Manager;Explorer;\n' >> "$out/share/applications/nemo.desktop"
    else
      sed -i 's/^Keywords=.*/Keywords=Nemo;File;Files;File Manager;Explorer;/' "$out/share/applications/nemo.desktop"
    fi
  '';

  # OPTIONAL: also override the D-Bus service so GTK_THEME applies when apps open folders via FileManager1
  nemoDbusServiceOverride = pkgs.runCommand "nemo-dbus-service-override" { meta.priority = 1; } ''
    set -euo pipefail
    mkdir -p "$out/share/dbus-1/services"
    for f in ${pkgs.nemo-with-extensions}/share/dbus-1/services/*.service; do
      bn="$(basename "$f")"
      cp "$f" "$out/share/dbus-1/services/$bn"
      chmod u+w "$out/share/dbus-1/services/$bn"
      # Prefix Exec with env GTK_THEME=... while preserving the original command/args
      sed -i 's|^Exec=|Exec=env GTK_THEME=${gtkThemeEnv} |' "$out/share/dbus-1/services/$bn"
    done
  '';

in

{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  # Explicitly disable logind idle handling to let GNOME manage it.
  services.logind.settings.Login = {
    IdleAction = "ignore";
    IdleActionSec = "0";
  };

  # To disable installing GNOME's suite of applications
  # and only be left with GNOME shell.
  services.gnome.core-apps.enable = true;
  services.gnome.core-developer-tools.enable = false;
  services.gnome.games.enable = false;
  environment.gnome.excludePackages = with pkgs; [
    atomix
    cheese
    epiphany
    evince
    geary
    gedit
    gnome-terminal
    hitori
    iagno
    tali
    totem
    gnome-tour
    cheese
    gnome-maps
    gnome-contacts
    gnome-calendar
    gnome-photos
    gnome-clocks
    gnome-music
    gnome-weather
    gnome-user-docs
    gnome-calculator
    gnome-console
    simple-scan
    decibels
  ];

  # for trash support in file managers
  services.gvfs.enable = true;

  # Helpful GNOME tooling
  environment.systemPackages =
    with pkgs;
    [
      adwaita-fonts
      adwaita-icon-theme
      baobab
      dconf-editor
      ffmpeg-headless
      ffmpegthumbnailer
      file-roller
      gnome-desktop
      gnome-extension-manager
      gnome-tweaks
      gst_all_1.gst-libav
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-ugly
      gst_all_1.gst-vaapi
      gst_all_1.gstreamer

      imagemagick
      kdePackages.qtstyleplugin-kvantum
      libsForQt5.qt5.qtgraphicaleffects
      nautilus
      nemo-with-extensions
      refine
      wl-clipboard
      gnome-themes-extra
      nemoDesktopOverride
      nemoDbusServiceOverride
    ]
    ++ (with pkgs.gnomeExtensions; [
      appindicator
      battery-health-charging
      bluetooth-quick-connect
      blur-my-shell
      caffeine
      clipboard-indicator
      ddterm
      gnome-40-ui-improvements
      gpu-supergfxctl-switch
      gsconnect
      light-style
      native-window-placement
      places-status-indicator
      removable-drive-menu
      system-monitor
      transparent-window-moving
      user-themes
      workspace-indicator
      wallpaper-slideshow
      paperwm
      tiling-shell
    ]);

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = [
      "gnome"
      "gtk"
      "*"
    ];
  };

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = theme;
  };

  networking.networkmanager.settings = {
    connectivity = {
      # Set to 0 to disable the check and remove the question mark
      # Or set to a reliable URL: "http://connectivity-check.ubuntu.com/"
      interval = 0;
    };
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;
  # Repeat configuration
  services.xserver.autoRepeatDelay = 220; # ms before repeating
  services.xserver.autoRepeatInterval = 25; # ms between repeats (~30/sec)
  services.xserver.videoDrivers = [ "nvidia" "amdgpu" ];
  services.libinput.enable = true;
  programs.firefox.enable = true;

  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        settings = {
          "org/gnome/desktop/interface" = {
            font-hinting = "none";
            color-scheme = if config.myTheme.preferDark then "prefer-dark" else "default";
          };

          "org/gnome/shell/extensions/blur-my-shell/panel" = {
            blur = false;
          };

          "org/gnome/shell/extensions/paperwm" = {
            disable-topbar-styling = true;
          };

          "system/locale" = {
            region = config.i18n.defaultLocale or "en_GB.UTF-8";
          };

          "org/gnome/shell" = {
            enabled-extensions = [
              "azwallpaper@azwallpaper.gitlab.com"
              "appindicatorsupport@rgcjonas.gmail.com"
              "Battery-Health-Charging@maniacx.github.com"
              "bluetooth-quick-connect@bjarosze.gmail.com"
              "blur-my-shell@aunetx"
              "caffeine@patapon.info"
              "clipboard-indicator@tudmotu.com"
              "ddterm@amezin.github.com"
              "drive-menu@gnome-shell-extensions.gcampax.github.com"
              "gnome-ui-tune@itstime.tech"
              "gpu-switcher-supergfxctl@chikobara.github.io"
              "gsconnect@andyholmes.github.com"
              "light-style@gnome-shell-extensions.gcampax.github.com"
              "native-window-placement@gnome-shell-extensions.gcampax.github.com"
              "places-menu@gnome-shell-extensions.gcampax.github.com"
              "system-monitor@gnome-shell-extensions.gcampax.github.com"
              "transparent-window-moving@noobsai.github.com"
              "user-theme@gnome-shell-extensions.gcampax.github.com"
              "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
              "paperwm@paperwm.github.com"
            ];
            disabled-extensions = [
              "windowsNavigator@gnome-shell-extensions.gcampax.github.com"
              "status-icons@gnome-shell-extensions.gcampax.github.com"
              "tilingshell@ferrarodomenico.com"
              "apps-menu@gnome-shell-extensions.gcampax.github.com"
              "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
              "BingWallpaper@sonichy"
              "window-list@gnome-shell-extensions.gcampax.github.com"
            ];
          };
        };
      }
    ];
  };

  # Generic desktop session environment vars (Wayland + Electron + Firefox)
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
    QT_STYLE_OVERRIDE = theme;
  };

  environment.etc."xdg/mimeapps.list".text = ''
    [Default Applications]
    inode/directory=nemo.desktop
    application/x-gnome-saved-search=nemo.desktop
    inode/file=nemo.desktop
    application/x-gnome-saved-search=nemo.desktop
    x-scheme-handler/file=nemo.desktop
  '';

  environment.etc."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-application-prefer-dark-theme=${if config.myTheme.preferDark then "1" else "0"}
  '';
}
