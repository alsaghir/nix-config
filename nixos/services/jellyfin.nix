# Jellyfin media server (web UI: http://localhost:8096).
#
# Serves the primary user's torrent downloads, bind-mounted read-only into the
# service's own mount namespace only (/home stays hidden from it). DLNA is an
# official plugin since 10.9 and is installed from the web UI
# (Dashboard -> Plugins -> Catalog -> DLNA). Add /media/torrents as a library.
#
# Control: systemctl {start,stop,status} jellyfin
{
  config,
  lib,
  ...
}:
let
  userLib = import ../../lib { inherit lib; };
  primaryUser = userLib.getPrimaryUserConfig config.networking.hostName;
  torrentsDir = "${primaryUser.homeDirectory}/Downloads/torrents";
in
{
  services.jellyfin = {
    enable = true;
    # 8096/8920 TCP (web), 1900 UDP (SSDP/DLNA), 7359 UDP (client discovery)
    openFirewall = true;

    # Transcode on the AMD iGPU (Ryzen 5900HS, VCN 2): power-efficient and keeps
    # the NVIDIA dGPU asleep. by-path is stable; renderD12x numbering is not.
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

  systemd.services.jellyfin.serviceConfig = {
    ProtectHome = true;
    BindReadOnlyPaths = [ "${torrentsDir}:/media/torrents" ];
  };

  users.users.jellyfin.extraGroups = [
    "render"
    "video"
  ];
}
