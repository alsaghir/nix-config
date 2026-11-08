# asus-laptop Jellyfin: serves the primary user's torrent downloads, transcodes on the AMD iGPU.
{ config, ... }:
let
  primaryUser = config.nixConfig.users.${config.nixConfig.primaryUser};
in
{
  nixConfig.services.jellyfin = {
    enable = true;
    mediaDirs.torrents = "${primaryUser.homeDirectory}/Downloads/torrents";
  };

  # Ryzen 5900HS iGPU (VCN 2): power-efficient and keeps the NVIDIA dGPU asleep.
  # by-path is stable; renderD12x numbering is not.
  services.jellyfin = {
    hardwareAcceleration = {
      enable = true;
      type = "vaapi";
      device = "/dev/dri/by-path/pci-0000:06:00.0-render";
    };
    transcoding = {
      enableHardwareEncoding = true;
      hardwareEncodingCodecs.hevc = true;
      hardwareDecodingCodecs = {
        h264 = true;
        hevc = true;
        hevc10bit = true;
        vp9 = true;
      };
    };
  };
}
