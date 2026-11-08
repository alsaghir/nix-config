# Bootloader for every host; the host picks the kind with nixConfig.core.boot.loader.
{ config, lib, ... }:
let
  cfg = config.nixConfig.core.boot;
in
{
  options.nixConfig.core.boot.loader = lib.mkOption {
    type = lib.types.enum [
      "systemd-boot"
      "grub-bios"
    ];
    default = "systemd-boot";
    description = ''
      systemd-boot: UEFI firmware (needs an EF00 ESP mounted at /boot).
      grub-bios: legacy BIOS/CSM boot from a GPT disk; needs a 1M EF02 partition in the
      host's disko layout, from which disko sets boot.loader.grub.devices. For firmware
      whose UEFI cannot boot Linux (e.g. home-server's 2012 ASUS P8Z68-V).
    '';
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.loader == "systemd-boot") {
      boot.loader.systemd-boot = {
        enable = true;
        configurationLimit = 8;
      };
      boot.loader.efi.canTouchEfiVariables = true;
    })
    (lib.mkIf (cfg.loader == "grub-bios") {
      boot.loader.grub = {
        enable = true;
        configurationLimit = 8;
      };
    })
  ];
}
