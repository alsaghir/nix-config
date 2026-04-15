{
  config,
  lib,
  userConfig,
  pkgs,
  ...
}:
{
  services.gnome-keyring.enable = true;
  gtk = {
    enable = true;
    theme = {
      name = if userConfig.preferences.theme == "dark" then "adwaita-dark" else "adwaita";
    };
    gtk4.theme = null;
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = if userConfig.preferences.theme == "dark" then 1 else 0;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = if userConfig.preferences.theme == "dark" then 1 else 0;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      font-hinting = "none";
      color-scheme = if userConfig.preferences.theme == "dark" then "prefer-dark" else "default";
      cursor-theme = "Adwaita";
      locate-pointer = true;
      clock-format = "12h";
      gtk-theme = if userConfig.preferences.theme == "dark" then "adwaita-dark" else "adwaita";
    };

    "org/gtk/settings/file-chooser" = {
      clock-format = "12h";
    };

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-timeout = lib.gvariant.mkUint32 1800;
      sleep-inactive-battery-timeout = lib.gvariant.mkUint32 1200;
    };

    "org/gnome/desktop/session" = {
      idle-delay = lib.gvariant.mkUint32 900;
    };

    "org/gnome/desktop/screensaver" = {
      lock-delay = lib.gvariant.mkUint32 300;
      restart-enabled = true;
    };

    "org/gnome/shell/extensions/Battery-Health-Charging" = {
      charging-mode = "max";
    };

    "org/gnome/shell/extensions/paperwm" = {
      disable-topbar-styling = true;
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };

    "org/gnome/shell" = {
      enabled-extensions = [
        "azwallpaper@azwallpaper.gitlab.com"
        "appindicatorsupport@rgcjonas.gmail.com"
        "Battery-Health-Charging@maniacx.github.com"
        "caffeine@patapon.info"
        "clipboard-indicator@tudmotu.com"
        "gsconnect@andyholmes.github.com"
        "gpu-switcher-supergfxctl@chikobara.github.io"
        "paperwm@paperwm.github.com"
        "tophat@fflewddur.github.io"
      ];
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome # GNOME-native portal (file chooser, etc.)
      xdg-desktop-portal-gtk # GTK fallback, covers org.gtk.Settings.FileChooser
    ];
    # Explicit portal routing — prevents ambiguity when multiple portals are present
    config.common.default = [
      "gnome"
      "gtk"
      "*"
    ];
  };

  qt.enable = true;

}
