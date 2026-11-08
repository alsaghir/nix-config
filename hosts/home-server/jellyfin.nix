# home-server Jellyfin. No mediaDirs yet: added when the data disks are reattached. CPU
# transcoding for now; Intel HD 3000 VA-API (intel-vaapi-driver, H.264 only) to be checked with vainfo.
{
  nixConfig.services.jellyfin.enable = true;
}
