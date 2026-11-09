# Data drives: one btrfs filesystem per disk (a dead disk loses only its own data), mounted by
# label. Kept out of disko.nix on purpose: disko formats the disks it manages on install.
# nofail: a missing/dead data disk must not block boot (the box stays reachable over SSH/RDP).
#   media  WD20EARX  2 TB    Jellyfin library
#   ahmed  WD3200AAJS 320 GB personal files
#   data   WD5000AAKX 500 GB spare; its SATA link is unreliable (interface errors), keep nothing
#                            irreplaceable on it until re-cabled and a scrub stays clean
{ ... }:
let
  dataDisk = label: {
    device = "/dev/disk/by-label/${label}";
    fsType = "btrfs";
    options = [
      "noatime"
      "compress=zstd"
      "nofail"
    ];
  };
in
{
  fileSystems = {
    "/srv/media" = dataDisk "media";
    "/srv/ahmed" = dataDisk "ahmed";
    "/srv/data" = dataDisk "data";
  };

  # Re-read every block monthly against its checksum; bit rot shows up in the journal.
  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [
      "/"
      "/srv/media"
      "/srv/ahmed"
      "/srv/data"
    ];
  };
}
