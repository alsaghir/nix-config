{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:

let

  userLib = import ../lib { inherit lib; };

  onlyofficeQtScale1 = userLib.mkQtScaledApp {
    inherit pkgs;

    pkg = pkgs.onlyoffice-desktopeditors;
    scale = "1";
    fontDpi = "96";
  };

in

{
  programs.mpv.enable = true;

  programs.firefox.enable = true;
  programs.firefox.configPath = "${config.xdg.configHome}/mozilla/firefox";

  programs.firefox.nativeMessagingHosts = [
    pkgs.firefoxpwa
  ];

  programs.ghostty.enable = true;
  programs.k9s.enable = true;
  programs.ptyxis.enable = true;
  programs.vesktop.enable = true;
  programs.vscode.enable = true;
  programs.chromium = {
    enable = true;
    package = pkgs.brave;
  };

  programs.zoxide.enable = true;
  gtk.enable = true;

  services.remmina.enable = true;

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

  programs.onlyoffice = {
    enable = true;
    package = onlyofficeQtScale1;
  };

  home.packages = with pkgs; [
    # mailspring
    (userLib.mkGSettingsApp {
      inherit pkgs;
      pkg = nomacs;
    })
    ente-auth

    biglybt

    antigravity
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

    xwayland-satellite

    slack
    (userLib.mkCleanGtk {
      inherit pkgs;
      pkg = pkgs.libreoffice;
    })

    gradia
    _7zz-rar
    unrar

    kdePackages.kate
    jetbrains-toolbox

  ];

}
