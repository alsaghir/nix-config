
{ config
, pkgs
, lib
, ...
}:
{
  # Asus stuff
  security.polkit.enable = true;
  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins;
  };
  hardware.i2c.enable = true;
  services.supergfxd.enable = true;
  services.asusd = {
    enable = true;
    enableUserService = true;
  };
  # This service forces the desired profile after boot
  systemd.services.set-asus-profile = {
    description = "Set Default ASUS Profile to Balanced";
    after = [
      "supergfxd.service"
      "asusd.service"
    ];
    requires = [ "asusd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "${pkgs.lib.makeBinPath [ pkgs.asusctl ]}/asusctl profile --profile-set Balanced";
    };
  };

  # =========================
  # Power management (TLP)
  # =========================
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = false;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "schedutil";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";
      USB_AUTOSUSPEND = 1;
      USB_DENYLIST = "8087:*";
      SATA_LINKPWR_ON_AC = "med_power_with_dipm";
      SATA_LINKPWR_ON_BAT = "min_power";
      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
      STOP_CHARGE_THRESH_BAT0 = "60";
    };
  };
}
