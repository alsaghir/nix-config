# ahmed on asus-laptop: niri desktop, personal apps, Flatpak, AI CLIs, personal SSH keys.
{ ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  sshKeysSopsFile = ./ssh-keys.yaml;

  wrappers = import ../../../lib/wrappers.nix { inherit lib; };

in
{

  imports = [
    ./justfile.nix
  ];

  nixConfig = {
    ai.enable = true;
    desktop.niri.enable = true;
    flatpak.enable = true;
  };

  programs.foliate.enable = true;
  programs.mpv.enable = true;
  programs.thunderbird.enable = true;
  programs.vesktop.enable = true;

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

  # Merged with home/desktop/common.nix (browser) and home/desktop/dms.nix.
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
    stamp

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

  # Personal SSH keys (age key: sops.age.keyFile in ../default.nix)
  sops.secrets = {
    ssh_private_key = {
      key = "ssh_private_key";
      path = "${config.home.homeDirectory}/.ssh/id_ed25519";
      mode = "0600";
      sopsFile = sshKeysSopsFile;

    };

    ssh_public_key = {
      key = "ssh_public_key";
      path = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      mode = "0644";
      sopsFile = sshKeysSopsFile;

    };

    rsa_ssh_private_key = {
      key = "rsa_ssh_private_key";
      path = "${config.home.homeDirectory}/.ssh/id_rsa";
      mode = "0600";
      sopsFile = sshKeysSopsFile;

    };

    rsa_ssh_public_key = {
      key = "rsa_ssh_public_key";
      path = "${config.home.homeDirectory}/.ssh/id_rsa.pub";
      mode = "0644";
      sopsFile = sshKeysSopsFile;

    };
  };
}
