# Samsung 860 EVO (the only disk attached during install). nixos-anywhere runs this layout
# ONCE and formats the disk; afterwards it only generates fileSystems.
# Legacy BIOS boot (nixConfig.core.boot.loader = "grub-bios"): the 1M EF02 partition holds
# GRUB's core image and makes disko set boot.loader.grub.devices to this disk.
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
    device = "/dev/disk/by-id/ata-Samsung_SSD_860_EVO_500GB_S4FNNE0M707417F";
    content = {
      type = "gpt";
      partitions = {
        bios = {
          size = "1M";
          type = "EF02";
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [
              "-f"
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
            };
          };
        };
      };
    };
  };
}
