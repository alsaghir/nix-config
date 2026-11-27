# home-server Jellyfin: torrent downloads (same as asus-laptop). Libraries on the data disks
# (storage.nix) are added by hand in the web UI with their /srv/... paths. CPU transcoding for
# now; Intel HD 3000 VA-API (intel-vaapi-driver, H.264 only) to be checked with vainfo.
{ config, lib, ... }:
let
  primaryUser = config.nixConfig.users.${config.nixConfig.primaryUser};
  torrents = "${primaryUser.homeDirectory}/Downloads/torrents";
in
{
  nixConfig.services.jellyfin = {
    enable = true;
    mediaDirs = { inherit torrents; };
  };

  # Start only once the (nofail) media disk is mounted, so a boot race never shows empty libraries.
  systemd.services.jellyfin.unitConfig.RequiresMountsFor = [ "/srv/media" ];

  # A missing bind source stops Jellyfin from starting; create the download folder up front.
  # Its parent too: tmpfiles would create a missing Downloads as root, then refuse the
  # ahmed -> root path transition and skip torrents (fresh installs, tests/home-server.nix).
  systemd.tmpfiles.settings."10-jellyfin-media" =
    lib.genAttrs [ (builtins.dirOf torrents) torrents ]
      (_: {
        d = {
          user = primaryUser.username;
          group = "users";
          mode = "0755";
        };
      });
}
