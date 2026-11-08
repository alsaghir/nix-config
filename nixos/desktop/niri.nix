# niri + DMS desktop, system side (the session itself: home/desktop/niri.nix).
{ config, lib, ... }:
{
  options.nixConfig.desktop.niri.enable = lib.mkEnableOption "the niri desktop (with DMS greeter)";

  config = lib.mkIf config.nixConfig.desktop.niri.enable {
    # The rest of this desktop; each can still be switched off individually.
    nixConfig.desktop = {
      common.enable = lib.mkDefault true;
      dms.enable = lib.mkDefault true;
    };

    programs.niri.enable = true;
    # Default true: Nautilus backs xdg-desktop-portal-gnome's FileChooser (same UI as the file manager).
    # programs.niri.useNautilus = false;

    # Nautilus full-text/metadata search. Indexes XDG dirs (Documents, Downloads, Pictures, …) + $HOME top level;
    # ~/Projects is not indexed. Change via dconf org/freedesktop/tracker/miner/files index-recursive-directories.
    # Status: localsearch status
    services.gnome.localsearch.enable = true;
    services.gnome.tinysparql.enable = true; # the store localsearch writes to
  };
}
