{
  lib,
  pkgs,
  ...
}:
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
      "com.bitwarden.desktop"
      "com.discordapp.Discord"
      "com.github.IsmaelMartinez.teams_for_linux"
      "com.github.tchx84.Flatseal"
      "com.microsoft.Edge"
      "com.slack.Slack"
      "im.nheko.Nheko"
      "info.smplayer.SMPlayer"
      "io.missioncenter.MissionCenter"
      "org.gnome.Evolution"
      "org.gnome.Fractal"
      "org.kde.kate"
      "org.kde.kcalc"
      "org.kde.konsole"
      "org.kde.neochat"
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
          talk-name = [
            "org.freedesktop.portal.Trash"
            "org.gtk.vfs.*"
          ];
        };
        Environment = {
          # Wrong cursor in flatpaks fix
          XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";
          QT_SCALE_FACTOR = "1.3";
          QT_FONT_DPI = "120"; # 96 DPI is default, 120 DPI is 125% scaling then 144 and so on
        };
      };
    };
    uninstallUnmanaged = false;

  };

  # This makes the Flatpak install/update run in the background
  # so 'nh os switch' doesn't wait for downloads.
  systemd.services.flatpak-managed-install = {
    wantedBy = lib.mkForce [ "multi-user.target" ]; # Start during normal boot
    before = lib.mkForce [ ]; # Remove the "block" on activation

    # Ensure the service doesn't kill the switch if it takes too long
    serviceConfig.TimeoutStartSec = "0";
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
