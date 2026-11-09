# Jellyfin media server (web UI: http://<host>:8096). Hosts set `mediaDirs` and, if the GPU
# allows, upstream services.jellyfin.{hardwareAcceleration,transcoding} (see hosts/<host>/jellyfin.nix).
#
# DLNA is an official plugin since 10.9 and is installed from the web UI
# (Dashboard -> Plugins -> Catalog -> DLNA).
#
# Control: systemctl {start,stop,status} jellyfin
{ config, lib, ... }:
let
  cfg = config.nixConfig.services.jellyfin;
in
{
  options.nixConfig.services.jellyfin = {
    enable = lib.mkEnableOption "the Jellyfin media server";
    mediaDirs = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        movies = "/mnt/media/Movies";
      };
      description = ''
        Host directories exposed read-only to Jellyfin as /media/<name>; add those paths as
        libraries in the web UI. Nothing else on the host (including /home) is visible to it.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      # 8096/8920 TCP (web), 1900 UDP (SSDP/DLNA), 7359 UDP (client discovery)
      openFirewall = true;
    };

    # Media is bind-mounted read-only into the service's own mount namespace. Entries are quoted
    # so paths may contain spaces; RequiresMountsFor waits for the (nofail) disks holding them.
    systemd.services.jellyfin = {
      unitConfig.RequiresMountsFor = map (path: ''"${path}"'') (lib.attrValues cfg.mediaDirs);
      serviceConfig = {
        ProtectHome = true;
        BindReadOnlyPaths = lib.mapAttrsToList (name: path: ''"${path}:/media/${name}"'') cfg.mediaDirs;
      };
    };

    # GPU access for hardware transcoding
    users.users.jellyfin.extraGroups = [
      "render"
      "video"
    ];
  };
}
