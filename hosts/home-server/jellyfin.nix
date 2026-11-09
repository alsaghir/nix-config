# home-server Jellyfin: torrent downloads (same as asus-laptop). Libraries on the data disks
# (storage.nix) are added by hand in the web UI with their /srv/... paths. CPU transcoding for
# now; Intel HD 3000 VA-API (intel-vaapi-driver, H.264 only) to be checked with vainfo.
{ config, ... }:
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
  systemd.tmpfiles.settings."10-jellyfin-media".${torrents}.d = {
    user = primaryUser.username;
    group = "users";
    mode = "0755";
  };
}
