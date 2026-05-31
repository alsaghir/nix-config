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

  # https://github.com/nix-community/nix-jetbrains-plugins
  ideaPlugins = [
    "com.fapiko.jetbrains.plugins.better_direnv"
    "com.github.copilot"
    "String Manipulation"
    "HighlightBracketPair"

    # KMP
    "com.intellij.nativeDebug"
    "androidx.compose.plugins.idea"
    "com.android.tools.design"
    "org.jetbrains.android"
    "com.jetbrains.kmm"
  ];

  ideaPluginsResolved = inputs.nix-jetbrains-plugins.lib.pluginsForIdeWith {
    extraOverrides = {
      "com.github.copilot" =
        plugin:
        plugin.overrideAttrs (old: {
          buildInputs = (old.buildInputs or [ ]) ++ [
            pkgs.libsecret
            pkgs.glib
            pkgs.libx11
            pkgs.libxtst
            pkgs.libjpeg8
            pkgs.libpng
            pkgs.pipewire
            pkgs.libei
          ];
        });
      "com.intellij.nativeDebug" =
        plugin:
        plugin.overrideAttrs (old: {
          buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.llvmPackages.lldb ];
        });
    };
  } pkgs pkgs.jetbrains.idea ideaPlugins;

  ideaWithPlugins = pkgs.jetbrains.plugins.addPlugins pkgs.jetbrains.idea (
    lib.attrValues ideaPluginsResolved
  );
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
  programs.lapce.enable = true;

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
    mailspring
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
    bitwarden-desktop
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
    #(inputs.nix-jetbrains-plugins.lib.buildIdeWithPlugins pkgs jetbrains.idea ideaPlugins)
    #ideaWithPlugins
  ];

}
