# niri desktop, system side (the session itself: home/desktop/niri.nix).
{ config, lib, ... }:
let
  cfg = config.nixConfig.desktop.niri;
in
{
  options.nixConfig.desktop.niri = {
    enable = lib.mkEnableOption "the niri desktop (with its shell's greeter)";

    # Mirrors the Home Manager option of the same name: each shell brings its own greeter.
    shell = lib.mkOption {
      type = lib.types.enum [
        "dms"
        "noctalia"
      ];
      default = "dms";
      description = "Desktop shell of the niri session; selects the matching greeter.";
    };
  };

  config = lib.mkIf cfg.enable {
    # The rest of this desktop; each can still be switched off individually.
    nixConfig.desktop = {
      common.enable = lib.mkDefault true;
      dms.enable = lib.mkDefault (cfg.shell == "dms");
      noctalia.enable = lib.mkDefault (cfg.shell == "noctalia");
    };

    # niri-only: on Plasma, KWin must launch the input method itself (System Settings → Virtual Keyboard).
    i18n.inputMethod = {
      enable = true;
      type = "ibus";
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
