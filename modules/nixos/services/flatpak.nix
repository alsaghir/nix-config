{ lib, pkgs, ... }:
{

  services.flatpak = {
    enable = true;

    # Explicit remotes; flathub is added by default if you don't override, but
    # declaring keeps intent clear and allows extension later.
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    # Sample application: Firefox (choose one that you do NOT already install via nixpkgs
    # if you want Flatpak auto-update behavior).
    packages = [
      "com.biglybt.BiglyBT"
      "com.bitwarden.desktop"
      "com.discordapp.Discord"
      "com.github.IsmaelMartinez.teams_for_linux"
      "com.github.tchx84.Flatseal"
      "com.microsoft.Edge"
      "com.slack.Slack"
      "info.smplayer.SMPlayer"
      "io.missioncenter.MissionCenter"
      "org.gnome.Evolution"
      "org.kde.kate"
      "org.kde.kcalc"
      "org.kde.konsole"
      "org.videolan.VLC"

      # You can mix forms:
      # { appId = "com.brave.Browser"; origin = "flathub"; }
    ];

    # Optional: enable periodic auto updates (they occur at system activation time).
    update = {
      onActivation = false;
      auto = {
        enable = true;
        onCalendar = "weekly"; # systemd OnCalendar expression
      };
    };

    # Only manage declared packages/remotes (default). Switch to true to prune
    # anything installed manually.
    # uninstallUnmanaged = true;

    # Example global overrides (customize later):
    # overrides.global = {
    #   Environment = {
    #     GTK_THEME = "Adwaita:dark"; This corrupts env, do not use globally
    #   };
    # };

    overrides = {
      global = {
        Context = {
          filesystems = [
            "/nix/store:ro"
            "/run/current-system/sw/bin:ro"
            "xdg-config/fontconfig:ro"
            "xdg-config/gtkrc:ro"
            "xdg-config/gtkrc-2.0:ro"
            "xdg-config/gtk-2.0:ro"
            "xdg-config/gtk-3.0:ro"
            "xdg-config/gtk-4.0:ro"
            "xdg-data/themes:ro"
            "xdg-data/icons:ro"
          ];
        };
        Environment = {
          # Wrong cursor in flatpaks fix
          XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";
        };
      };
    };
    uninstallUnmanaged = false;

  };

  system.activationScripts.someScriptUsingSudo = {
    text = ''
      export PATH=${
        lib.makeBinPath [
          pkgs.unzip
        ]
      }:$PATH

      echo "Running some script using Sudo ..." >&2
    '';
    deps = [ ]; # deps are usually inferred, leaving it empty is fine
  };

}
