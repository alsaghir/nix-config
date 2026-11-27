{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixConfig.hardware.asus;

  # asusd restores its last settings from /etc/asusd/asusd.ron, which `asusctl` edits at runtime;
  # these oneshots re-apply the declared values on every boot instead.
  asusctlOneshot = description: args: {
    inherit description;
    after = [
      "supergfxd.service"
      "asusd.service"
      "dbus.service"
    ];
    requires = [ "asusd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
      User = "root";
      ExecStart = "${lib.getExe' pkgs.asusctl "asusctl"} ${lib.escapeShellArgs args}";
    };
  };
in
{
  options.nixConfig.hardware.asus = {
    enable = lib.mkEnableOption "ASUS laptop support (asusd, supergfxd, OpenRGB)";

    chargeLimit = lib.mkOption {
      type = lib.types.nullOr (lib.types.ints.between 20 100);
      default = null;
      example = 60;
      description = ''
        Battery charge limit in percent, applied through asusd (which re-applies it after resume).
        null leaves whatever was last set by asusctl or a shell's power settings.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
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
    };
    systemd.services = {
      set-asus-profile = asusctlOneshot "Set Default ASUS Profile to Balanced" [
        "profile"
        "set"
        "Balanced"
      ];
      set-asus-charge-limit = lib.mkIf (cfg.chargeLimit != null) (
        asusctlOneshot "Set ASUS battery charge limit" [
          "battery"
          "limit"
          (toString cfg.chargeLimit)
        ]
      );
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
      };
    };
  };
}
