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
  programs.plasma.enable = true;
  programs.plasma.configFile.kwinrc = {
    Plugins.desktopchangeosdEnabled = true;
    Plugins.dynamic_workspacesEnabled = true;
    Plugins.krohnkiteEnabled = true;
    Desktops.Rows = 1;

    Script-krohnkite = {
      screenGapBetween = 6;
      screenGapBottom = 6;
      screenGapLeft = 6;
      screenGapRight = 6;
      screenGapTop = 6;
    };

    Windows = {
      FocusPolicy = "FocusFollowsMouse";

    };
  };

  programs.plasma.configFile."plasma-org.kde.plasma.desktop-appletsrc" = {

  };

  programs.plasma.configFile.kdeglobals = {
    WM = {
      frame = "61,174,233";
      inactiveFrame = "239,240,241";
    };

  };

  programs.plasma.shortcuts = {
    kwin = {
      "Window Maximize" = [
        "Meta+F"
        "Maximize Window"
      ];
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
