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
    ai.enable = false;
    desktop.niri.enable = true;
    flatpak.enable = true;
  };

  programs.foliate.enable = true;
  programs.mpv.enable = true;
  programs.thunderbird.enable = true;
  programs.vesktop.enable = true;
  programs.gh.enable = true;

  # Desktop widgets (home/desktop/dms.nix). Positions live in session.json, keyed by the widget ids
  # from settings.json. syncPositionAcrossScreens stores one "_synced" position, as fractions of the
  # screen, used on every output, including ones not in hosts/asus-laptop/displays.nix.
  programs.dank-material-shell =
    let
      clock = "dw_1794843642879_yxovj2l9a";
      systemMonitor = "dw_1794843747110_p3mp8c4pv";
      # Top-right corner: offsets (px) from the right/top edge, as laid out on DP-1.
      reference = config.nixConfig.displays.DP-1;
      topRight = size: rightOffset: {
        _synced = size // {
          x = rightOffset / (reference.width * 1.0);
          y = 60 / (reference.height * 1.0);
          anchorX = "end";
        };
      };
      common = {
        transparency = 0.8;
        colorMode = "secondary";
        customColor = "#ffffff";
        displayPreferences = [ "all" ];
        syncPositionAcrossScreens = true;
      };
    in
    {
      settings.desktopWidgetInstances = [
        {
          id = clock;
          widgetType = "desktopClock";
          name = "Clock";
          enabled = true;
          config = common // {
            style = "analog";
            showDate = true;
            showAnalogNumbers = true;
            showAnalogSeconds = false;
          };
        }
        {
          id = systemMonitor;
          widgetType = "systemMonitor";
          name = "System Monitor";
          enabled = true;
          config = common // {
            showHeader = true;
            showCpu = true;
            showCpuGraph = true;
            showCpuTemp = true;
            showGpuTemp = true;
            gpuPciId = "10de:249d"; # NVIDIA dGPU, from `lspci -nn`
            showMemory = true;
            showMemoryGraph = true;
            showNetwork = true;
            showNetworkGraph = true;
            showDisk = false;
            showTopProcesses = true;
            topProcessCount = 10;
            topProcessSortBy = "cpu";
            layoutMode = "auto";
            graphInterval = 300;
          };
        }
      ];
      session = {
        desktopWidgetInstancePositions = {
          ${clock} = topRight {
            width = 200;
            height = 200;
          } 110;
          ${systemMonitor} = topRight {
            width = 320;
            height = 480;
          } 350;
        };
        desktopWidgetGridSettings.DP-1 = {
          enabled = true;
          size = 30;
        };
      };
    };
  # misterdownloadmanager registers its own browser host (~/.mozilla, Edge, ...) at every start,
  # with its current store path. Don't also list it in programs.firefox.nativeMessagingHosts:
  # the app writes through home-manager's symlink into the read-only store and fails.

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
