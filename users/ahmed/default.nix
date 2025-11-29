{
  config,
  pkgs,
  pkgsStable,
  lib,
  osConfig,
  ...
}:
let
  isGnome = osConfig.services.desktopManager.gnome.enable or false;
in
{
  home.username = "ahmed";
  home.homeDirectory = "/home/ahmed";

  # Zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "cp"
        "history"
        "kind"
        "kubectl"
        "podman"
        "ssh"
        "ssh-agent"
        "sudo"
        "systemd"
      ];
    };

    initContent =
      let
        zshConfigEarlyInit = lib.mkOrder 500 ''
          echo "Early init"
          # source /etc/profile
        '';
        zshConfigBeforeCompletionInit = lib.mkOrder 550 ''echo "Before completion init"'';
        zshConfig = lib.mkOrder 1000 ''echo "General Config init"'';
        zshConfigLastToRun = lib.mkOrder 1500 ''
          echo "Last to run init"

          # Mise activation for zsh
          # eval "$(mise activate zsh)"

          # Nix auto-completion if you have it
          if command -v determinate-nixd >/dev/null 2>&1; then
            eval "$(determinate-nixd completion zsh)"
          fi
        '';
      in
      lib.mkMerge [
        zshConfigEarlyInit
        zshConfigBeforeCompletionInit
        zshConfig
        zshConfigLastToRun
      ];
  };

  # Proper starship via HM (adds the init line automatically)
  programs.starship.enable = true;

  # Optional nice CLI tools
  programs.zoxide.enable = true;
  programs.fzf.enable = true;

  # User-level packages (not strictly needed system-wide)
  home.packages =
    with pkgs;
    [
      jetbrains-toolbox
      bash
      usbutils
      mesa-demos
      vulkan-tools
      fastfetch
      kdePackages.konsole
      terminator
      kdePackages.kcalc
      code-cursor
      unzip

      kotlin
      temurin-bin-21
      gemini-cli

      nixfmt-rfc-style
      statix
      deadnix
      nix-output-monitor
      nvd
      nix-diff
      nix-tree
      nix-index
      nil
    ]
    ++ lib.optionals isGnome (
      with pkgs.gnomeExtensions;
      [
        appindicator
        battery-health-charging
        bluetooth-quick-connect
        blur-my-shell
        caffeine
        clipboard-indicator
        ddterm
        gnome-40-ui-improvements
        gpu-supergfxctl-switch
        gsconnect
        light-style
        native-window-placement
        places-status-indicator
        removable-drive-menu
        system-monitor
        transparent-window-moving
        user-themes
        workspace-indicator
        wallpaper-slideshow

        paperwm
        tiling-shell
      ]
    );

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "github" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        extraOptions = {
          AddKeysToAgent = "yes";
          IdentitiesOnly = "yes";
          PreferredAuthentications = "publickey";
        };
      };
      "*" = {
        identityFile = "~/.ssh/id_ed25519";
        extraOptions = {
          AddKeysToAgent = "yes";
          IdentitiesOnly = "yes";
        };
        user = "git";
      };
    };
  };

  # Shell and small conveniences
  home.shellAliases = {
    gpustat = "nvidia-smi";
    offload-gl = "__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo -B | egrep 'OpenGL (vendor|renderer)'";
  };

  programs.git.enable = true;

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
  xdg.desktopEntries.nemo = {
    name = "Nemo";
    exec = "${pkgs.nemo-with-extensions}/bin/nemo";
  };

  # Just placeholder if wanted to install and activate
  # extensions using different way
  programs.gnome-shell = lib.mkIf isGnome {
    enable = false;
    extensions = [
      { package = pkgs.gnomeExtensions.caffeine; }
    ];
  };
  dconf = lib.mkIf isGnome {
    enable = true;
    settings = {
      "org/gnome/shell" = {
        # disable-user-extensions = true; # Optionally disable user extensions entirely
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
      "system/locale" = {
        region = osConfig.i18n.defaultLocale or "en_GB.UTF-8";
      };
      "org/cinnamon/desktop/applications/terminal" = {
            exec = "konsole";
        };
    };
  };

  # Set HM state version (match current release; do not bump casually)
  home.stateVersion = "25.05";
}
