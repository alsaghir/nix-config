{ pkgs, ... }:
{
  programs.niri.enable = true;
  # Default true: Nautilus backs xdg-desktop-portal-gnome's FileChooser (same UI as the file manager).
  # programs.niri.useNautilus = false;

  # Nautilus full-text/metadata search. Indexes XDG dirs (Documents, Downloads, Pictures, …) + $HOME top level;
  # ~/Projects is not indexed. Change via dconf org/freedesktop/tracker/miner/files index-recursive-directories.
  # Status: localsearch status
  services.gnome.localsearch.enable = true;
  services.gnome.tinysparql.enable = true; # the store localsearch writes to
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

}
