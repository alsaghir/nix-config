# ahmed on asus-laptop: KDE Plasma desktop, personal apps, Flatpak, AI CLIs, personal SSH keys.
{ ... }:
{
  lib,
  pkgs,
  ...
}:
let
  wrappers = import ../../../lib/wrappers.nix { inherit lib; };
in
{
  imports = [
    ./justfile.nix
    # Inert while DMS is off; kept so switching back to niri is one flag.
    ./dms-widgets.nix
  ];

  nixConfig = {
    ai.enable = true;
    desktop.plasma.enable = true;
    flatpak.enable = true;

    # Personal keys (age key: sops.age.keyFile in ../default.nix).
    ssh-keys = {
      sopsFile = ./ssh-keys.yaml;
      files = {
        id_ed25519.key = "ssh_private_key";
        "id_ed25519.pub".key = "ssh_public_key";
        id_rsa.key = "rsa_ssh_private_key";
        "id_rsa.pub".key = "rsa_ssh_public_key";
      };
    };
  };

  programs = {
    antigravity.enable = true;
    foliate.enable = true;
    gh.enable = true;
    mpv.enable = true;
    thunderbird.enable = true;
    vesktop.enable = true;
  };

  services.remmina.enable = true;
  # HM's unit has Requires= but no After=graphical-session.target, so it starts in parallel
  # with the compositor, finds no WAYLAND_DISPLAY ("cannot open display") and hits the start limit.
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

  # Merged with home/desktop/common.nix (browser) and the active desktop module.
  xdg.mimeApps.defaultApplications = {
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

  home.packages = with pkgs; [
    (wrappers.mkGSettingsApp {
      inherit pkgs;
      pkg = nomacs;
    })
    ente-auth
    biglybt
    mission-center
    microsoft-edge
    smplayer
    vlc
    haruna
    (wrappers.mkGSettingsApp {
      inherit pkgs;
      pkg = krita;
      primaryDesktopFile = "org.kde.krita.desktop";
    })
    slack
    (wrappers.mkCleanGtk {
      inherit pkgs;
      pkg = pkgs.libreoffice;
    })
    gradia
    _7zz-rar
    unrar
    jetbrains-toolbox
    proton-vpn
    github-copilot-app
    # Registers its own browser host (~/.mozilla, Edge, ...) at every start, with its current
    # store path. Don't also list it in programs.firefox.nativeMessagingHosts: the app writes
    # through home-manager's symlink into the read-only store and fails.
    misterdownloadmanager

    # GPU / input diagnostics
    mesa-demos
    vulkan-tools
    libinput
  ];

  services.flatpak.packages = [
    "com.getpostman.Postman"
    "com.github.IsmaelMartinez.teams_for_linux"
    "com.github.tchx84.Flatseal"
  ];
}
