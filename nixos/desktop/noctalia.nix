# Noctalia greeter (login screen; bundles its own wlroots compositor). Enabled by nixConfig.desktop.niri
# when its shell is "noctalia". Theme and wallpaper come from the Noctalia shell's Settings → Security →
# Sync, which writes /var/lib/noctalia-greeter/sync.toml; greeter.toml below would override it, so it
# only declares what Sync can't know.
{ config, lib, ... }:
let
  inherit (config.nixConfig) displays primaryUser;

  # The greeter's mapping syntax ("DP-1:0,0;HDMI-A-1:2560,0"). Its compositor splits on ';' without
  # trimming, hence no spaces.
  mapping =
    value:
    lib.concatStringsSep ";" (
      lib.mapAttrsToList (name: v: "${name}:${v}") (lib.filterAttrs (_: v: v != null) value)
    );
  perDisplay = f: mapping (lib.mapAttrs (_: f) displays);
  optionalNum = n: if n == null then null else toString n;
in
{
  options.nixConfig.desktop.noctalia.enable =
    lib.mkEnableOption "the Noctalia greeter (login screen)";

  config = lib.mkIf config.nixConfig.desktop.noctalia.enable {
    services.displayManager.noctalia-greeter = {
      enable = true;
      # Appearance-only sync from the shell, without an admin password each time.
      passwordlessSyncUsers = [ primaryUser ];
      settings = {
        user.default = primaryUser;
        keyboard.numlock = true;
        # From nixConfig.displays (hosts/<host>/displays.nix), same source as the niri session.
        output = lib.filterAttrs (_: v: v != "") {
          layout = perDisplay (d: "${toString d.x},${toString d.y}");
          scales = perDisplay (d: optionalNum d.scale);
          refresh_rate = perDisplay (d: optionalNum d.refresh);
        };
      };
    };

    security.pam.services.greetd.enableGnomeKeyring = true;
  };
}
