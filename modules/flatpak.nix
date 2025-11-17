{ lib, ... }:
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
      "io.missioncenter.MissionCenter"
      "com.biglybt.BiglyBT"
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
  };
}
