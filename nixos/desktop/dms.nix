{ config, lib, ... }:
let
  # Greeter outputs generated from nixConfig.displays (hosts/<host>/displays.nix), same source as home/niri.nix.
  outputKdl =
    name: d:
    let
      refresh = lib.optionalString (d.refresh != null) "@${toString d.refresh}";
    in
    ''
      output "${name}" {
          mode "${toString d.width}x${toString d.height}${refresh}"
          position x=${toString d.x} y=${toString d.y}
      ${lib.optionalString (d.scale != null) "    scale ${toString d.scale}\n"}}
    '';
in
{
  # nixpkgs module (formerly programs.dank-material-shell.greeter from the DMS flake)
  services.displayManager.dux-greeter = {
    enable = true;
    compositor = {
      name = "niri";
      # Greeter config (separate niri instance). DMS display profiles and kanshi don't apply here,
      # so every display stays on at login.
      customConfig = ''
        input {
            keyboard {
                numlock
            }
        }
        ${lib.concatStrings (lib.mapAttrsToList outputKdl config.nixConfig.displays)}'';
    };
  };

  # The module's preStart runs `chown *`, which skips dotfiles, so a .cache left by an older
  # greeter (different UID) blocks "Extracting embedded UI". Z = recursive chown at every boot.
  systemd.tmpfiles.settings."10-dms-greeter"."/var/lib/dms-greeter".Z = {
    user = "dms-greeter";
    group = "dms-greeter";
  };
}
