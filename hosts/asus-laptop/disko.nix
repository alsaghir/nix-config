# Declarative description of the laptop's EXISTING disk layout.
# Used only to generate fileSystems; it never touches the disk on rebuild.
# NEVER run the `disko` CLI / formatScript on this machine — that formats it.
#
# Partitions are pinned to their current PARTUUIDs (`uuid`), so disko mounts
# them via /dev/disk/by-partuuid/… and a reinstall would recreate the same IDs.
# Layout: p1 = btrfs (fills disk minus 4G), p2 = 4G ESP at the end of the disk.
let
  btrfsOpts = [
    "compress=zstd"
    "noatime"
    "discard=async"
  ];
in
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-HFM001TD3JX013N_CY0CN03401180CH55";
    content = {
      type = "gpt";
      partitions = {
        root = {
          uuid = "d2469851-3f61-447e-bee8-0f118c504645";
          end = "-4G";
          content = {
            type = "btrfs";
            extraArgs = [
              "-L"
              "nixroot"
            ];
            subvolumes = {
              "@" = {
                mountpoint = "/";
                mountOptions = btrfsOpts;
              };
              "@home" = {
                mountpoint = "/home";
                mountOptions = btrfsOpts;
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = btrfsOpts;
              };
              "@var_log" = {
                mountpoint = "/var/log";
                mountOptions = btrfsOpts;
              };
              # Swapfile lives here (see swapDevices in default.nix); no compression.
              "@swap" = {
                mountpoint = "/swap";
                mountOptions = [
                  "compress=none"
                  "noatime"
                  "discard=async"
                ];
              };
            };
          };
        };
        ESP = {
          uuid = "ccaa4063-9d0f-427e-999d-871d976a2073";
          type = "EF00";
          size = "100%";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "fmask=0077"
              "dmask=0077"
            ];
          };
        };
      };
    };
  };
}
