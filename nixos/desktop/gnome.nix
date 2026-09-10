{
  config,
  pkgs,
  lib,
  hostname,
  ...
}:

let
  gdmMonitorsConfig = pkgs.writeText "gdm_monitors.xml" ''
    <monitors version="2">
      <configuration>
        <layoutmode>logical</layoutmode>
        <logicalmonitor>
          <x>0</x>
          <y>0</y>
          <scale>1</scale>
          <primary>yes</primary>
          <monitor>
            <monitorspec>
              <connector>DP-1</connector>
              <vendor>AOC</vendor>
              <product>Q27G4Z</product>
              <serial>2RRR9HA014571</serial>
            </monitorspec>
            <mode><width>2560</width><height>1440</height><rate>120.000</rate></mode>
          </monitor>
        </logicalmonitor>
        <logicalmonitor>
          <x>2560</x>
          <y>0</y>
          <scale>1</scale>
          <monitor>
            <monitorspec>
              <connector>HDMI-1</connector>
              <vendor>AOC</vendor>
              <product>Q27G4</product>
              <serial>18DQ5HA063266</serial>
            </monitorspec>
            <mode><width>2560</width><height>1440</height><rate>60.000</rate></mode>
          </monitor>
        </logicalmonitor>
        <logicalmonitor>
          <x>0</x>
          <y>1440</y>
          <scale>1</scale>
          <monitor>
            <monitorspec>
              <connector>eDP-1</connector>
              <vendor>CMN</vendor>
              <product>0x152a</product>
              <serial>0x00000000</serial>
            </monitorspec>
            <mode><width>2560</width><height>1440</height><rate>60.000</rate></mode>
          </monitor>
        </logicalmonitor>
      </configuration>
    </monitors>
  '';
in

{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  programs.dconf.enable = true;
  # Explicitly disable logind idle handling to let GNOME manage it.
  services.logind.settings.Login = {
    IdleAction = "ignore";
    IdleActionSec = "0";
  };

  # To disable installing GNOME's suite of applications
  # and only be left with GNOME shell.
  services.gnome.core-apps.enable = true;
  services.gnome.core-developer-tools.enable = false;
  services.gnome.games.enable = false;
  services.dbus.packages = [ pkgs.dconf ];

  environment.gnome.excludePackages = with pkgs; [
    atomix
    cheese
    epiphany
    evince
    gedit
    hitori
    iagno
    tali
    totem
    gnome-tour
    cheese
    gnome-maps
    gnome-music
    gnome-user-docs
    simple-scan
    decibels
  ];

  networking.networkmanager.settings = {
    connectivity = {
      # Set to 0 to disable the check and remove the question mark
      # Or set to a reliable URL: "http://connectivity-check.ubuntu.com/"
      interval = 0;
    };
  };

  # Generic desktop session environment vars (Wayland + Electron + Firefox)
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    # QT_SCALE_FACTOR = "1";
    # QT_FONT_DPI = "96";
  };

  programs.evolution = {
    enable = true;
    plugins = with pkgs; [
      evolution-ews
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/gdm/seat0 0711 gdm gdm -"
    "d /var/lib/gdm/seat0/config 0711 gdm gdm -"
    "L+ /var/lib/gdm/seat0/config/monitors.xml - - - - ${gdmMonitorsConfig}"
  ];
}
