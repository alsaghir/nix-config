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
      name = "Adwaita-dark";
      package = pkgs.gnome.gnome-themes-extra;
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
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
      exec = "env GTK_THEME=Adwaita:dark ${pkgs.nemo-with-extensions}/bin/nemo %U";
      mimeType = [
        "inode/directory"
        "application/x-gnome-saved-search"
      ];
      icon = "nemo";
    };
    xdg.desktopEntries."org.kde.kcalc" = {
      name = "KCalc";
      exec = "env QT_STYLE_OVERRIDE=adwaita kcalc";
      icon = "kcalc";
      comment = "Scientific Calculator";
      categories = [
        "Utility"
        "Calculator"
      ];
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
        # Home Manager will now automatically populate 'enabled-extensions'
        # You can keep this block if you need to manage disabled ones.
        "org/gnome/shell" = {
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
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-theme = "Adwaita-dark";
        };
      };
    };
  };
}
