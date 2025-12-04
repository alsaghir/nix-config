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
      "com.github.tchx84.Flatseal"
      "com.github.IsmaelMartinez.teams_for_linux"
      "info.smplayer.SMPlayer"
      "com.discordapp.Discord"
      "com.microsoft.Edge"
      "com.biglybt.BiglyBT"
      "org.gtk.Gtk3theme.Orchis"
      "org.gtk.Gtk3theme.Orchis-Dark"
      "org.gtk.Gtk3theme.Yaru"
      "org.gtk.Gtk3theme.Yaru-dark"
      "org.gtk.Gtk3theme.adw-gtk3"
      "org.gtk.Gtk3theme.adw-gtk3-dark"
      # You can mix forms:
      # { appId = "com.brave.Browser"; origin = "flathub"; }
    ];

    # Optional: enable periodic auto updates (they occur at system activation time).
    update.auto = {
      enable = true;
      onCalendar = "weekly"; # systemd OnCalendar expression
    };

    # Only manage declared packages/remotes (default). Switch to true to prune
    # anything installed manually.
    # uninstallUnmanaged = true;

    # Example global overrides (customize later):
    # overrides.global = {
    #   Environment = {
    #     GTK_THEME = "Adwaita:dark";
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

  system.activationScripts.patchBiglyBT = {
    text = ''
      export PATH=${
        lib.makeBinPath [
          pkgs.flatpak
          pkgs.unzip
          pkgs.gnutar
          pkgs.gzip
          pkgs.coreutils
        ]
      }:$PATH

      echo "Patching BiglyBT..." >&2
    '';
    deps = [ ]; # deps are usually inferred, leaving it empty is fine
  };

}
