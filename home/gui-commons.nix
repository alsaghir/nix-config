{
  pkgs,
  lib,
  config,
  ...
}:

let

  userLib = import ../lib { inherit lib; };

in

{
  programs.mpv.enable = true;
  programs.foliate.enable = true;

  programs.firefox = {
    enable = true;
    configPath = "${config.xdg.configHome}/mozilla/firefox";
    nativeMessagingHosts = [
      pkgs.firefoxpwa
    ];
  };

  programs.thunderbird.enable = true;

  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "Hack Nerd Font";
      font-size = 12;
    };
  };
  programs.k9s.enable = true;
  programs.vesktop.enable = true;
  programs.vscode = {
    enable = true;
    # VS Code picks the keyring from XDG_CURRENT_DESKTOP and doesn't know "niri"; name it explicitly.
    argvSettings = {
      password-store = "gnome-libsecret";
      enable-crash-reporter = false;
    };
  };

  programs.zoxide.enable = true;
  gtk.enable = true;

  services.remmina.enable = true;
  # HM's unit has Requires= but no After=graphical-session.target, so it starts in parallel
  # with niri, finds no WAYLAND_DISPLAY ("cannot open display") and hits the start limit.
  systemd.user.services.remmina.Unit.After = [ "graphical-session.target" ];

  xdg.configFile."autostart/vesktop.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Name=Vesktop
      Exec=vesktop %U
      Icon=vesktop
      Type=Application
      X-KDE-autostart-phase=2
    '';
  };

  # ~/.config/mimeapps.list is now Nix-owned (read-only). Only list types claimed by several apps;
  # a type with a single claimant already resolves on its own. More defaults in home/dms.nix (merged).
  # Find claimants:  grep -l '<mime>' ~/.nix-profile/share/applications/*.desktop
  # Current default: xdg-mime query default <mime>
  # If an app fails to register a handler at runtime, add its line here.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "text/html" = "firefox.desktop";
      "x-scheme-handler/discord" = "vesktop.desktop";
      "x-scheme-handler/slack" = "slack.desktop";
      # Written at runtime by their tools into ~/.local/share/applications
      "x-scheme-handler/jetbrains" = "jetbrainsd.desktop";
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
    }
    // lib.genAttrs [
      "image/png"
      "image/jpeg"
      "image/gif"
      "image/webp"
      "image/bmp"
      "image/tiff"
    ] (_: "org.nomacs.ImageLounge.desktop");
  };

  home.packages = with pkgs; [
    # mailspring
    (userLib.mkGSettingsApp {
      inherit pkgs;
      pkg = nomacs;
    })
    ente-auth

    biglybt

    mission-center

    adwaita-icon-theme
    microsoft-edge
    smplayer
    vlc
    haruna
    # bitwarden-desktop
    (userLib.mkGSettingsApp {
      inherit pkgs;
      pkg = krita;
      primaryDesktopFile = "org.kde.krita.desktop";
    })

    slack
    (userLib.mkCleanGtk {
      inherit pkgs;
      pkg = pkgs.libreoffice;
    })

    gradia
    _7zz-rar
    unrar

    jetbrains-toolbox
    proton-vpn
    github-copilot-app

    stamp

  ];

}
