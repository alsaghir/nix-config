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
  programs.gnome-shell = lib.mkIf isGnome {
    enable = true; 
    extensions = with pkgs.gnomeExtensions; [
      { package = appindicator; }
      { package = battery-health-charging; }
      { package =  bluetooth-quick-connect; }
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

  # Gnome configurations using home manager
  gtk.theme = lib.mkIf isGnome {
    name = "Orchis-Dark";
    package = pkgs.orchis-theme;
  };

  xdg.mimeApps = lib.mkIf isGnome {
    enable = true;
    defaultApplications = {
      "inode/directory" = "nemo.desktop";
      "application/x-gnome-saved-search" = [ "nemo.desktop" ];
    };
  };
  xdg.desktopEntries.nemo = lib.mkIf isGnome {
    name = "Nemo";
    exec = "${pkgs.nemo-with-extensions}/bin/nemo";
  };

  # We can now remove the hardcoded 'enabled-extensions' list
  dconf = lib.mkIf isGnome {
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
    };
  };
}
