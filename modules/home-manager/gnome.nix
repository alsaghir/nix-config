{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  isGnome = osConfig.services.desktopManager.gnome.enable or false;
in
{
  config = lib.mkIf isGnome {
    programs.gnome-shell = {
      enable = true;
      extensions = with pkgs.gnomeExtensions; [
        { package = appindicator; }
        { package = battery-health-charging; }
        { package = bluetooth-quick-connect; }
        { package = blur-my-shell; }
        { package = caffeine; }
        { package = clipboard-indicator; }
        { package = ddterm; }
        { package = gnome-40-ui-improvements; }
        { package = gpu-supergfxctl-switch; }
        { package = gsconnect; }
        { package = light-style; }
        { package = native-window-placement; }
        { package = places-status-indicator; }
        { package = removable-drive-menu; }
        { package = system-monitor; }
        { package = transparent-window-moving; }
        { package = user-themes; }
        { package = workspace-indicator; }
        { package = wallpaper-slideshow; }
        { package = paperwm; }
        { package = tiling-shell; }
      ];
    };

    # Wayland, X, etc. support for session vars
    systemd.user.sessionVariables = config.home.sessionVariables;

    # Gnome configurations using home manager
    gtk.theme = {
      name = if osConfig.myTheme.preferDark then "Adwaita-dark" else "Adwaita";
      package = pkgs.gnome.gnome-themes-extra;
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = if osConfig.myTheme.preferDark then 1 else 0;
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = if osConfig.myTheme.preferDark then 1 else 0;
      };
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = "nemo.desktop";
        "application/x-gnome-saved-search" = [ "nemo.desktop" ];
      };
    };
    xdg.desktopEntries.nemo = {
      name = "Nemo";
      # or Adwaita:dark
      exec = "env GTK_THEME=${
        if osConfig.myTheme.preferDark then "Adwaita:dark" else "Adwaita"
      } ${pkgs.nemo-with-extensions}/bin/nemo %U";
      mimeType = [
        "inode/directory"
        "application/x-gnome-saved-search"
      ];
      icon = "nemo";
    };

    # We can now remove the hardcoded 'enabled-extensions' list
    dconf = {
      enable = true;
      settings = {
        "system/locale" = {
          region = osConfig.i18n.defaultLocale or "en_GB.UTF-8";
        };
        "org/cinnamon/desktop/applications/terminal" = {
          exec = "konsole";
        };
        "org/gnome/shell/extensions/blur-my-shell/panel" = {
          blur = false;
        };
        "org/gnome/shell/extensions/paperwm" = {
          disable-topbar-styling = true;
        };
        "org/gnome/desktop/interface" = {
          color-scheme = if osConfig.myTheme.preferDark then "prefer-dark" else "default";
        };

        # Home Manager will now automatically populate 'enabled-extensions'
        # You can keep this block if you need to manage disabled ones.
        "org/gnome/shell" = {
          enabled-extensions = [
            "azwallpaper@azwallpaper.gitlab.com"
            "appindicatorsupport@rgcjonas.gmail.com"
            "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
            "Battery-Health-Charging@maniacx.github.com"
            "bluetooth-quick-connect@bjarosze.gmail.com"
            "blur-my-shell@aunetx"
            "caffeine@patapon.info"
            "clipboard-indicator@tudmotu.com"
            "ddterm@amezin.github.com"
            "drive-menu@gnome-shell-extensions.gcampax.github.com"
            "gnome-ui-tune@itstime.tech"
            "gpu-switcher-supergfxctl@chikobara.github.io"
            "gsconnect@andyholmes.github.io"
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
    };
  };
}
