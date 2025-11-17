{ config, pkgs, ... }:
{
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  # Explicitly install BlueZ tools (bluetoothctl, etc.) only when BT is enabled.
  hardware.bluetooth.package = pkgs.bluez;
  
  services.upower.enable = true;
  # Optional explicit package: hardware.bluetooth.package = pkgs.bluez;
  # For KDE-native tray, do not enable blueman here.
  # services.blueman.enable = true; # optional GUI manager (useful even on KDE)
  # For extra BlueZ plugins/features:
  #hardware.bluetooth.package = pkgs.bluezFull;
  boot.extraModprobeConfig = ''
    options btusb disable_sleep=Y
    '';
  # BlueZ main.conf settings to favor LE/HOGP stability
  hardware.bluetooth.settings = {
    General = {
      Experimental = true;                     # Extra plugins (set false if unstable)
      ControllerMode = "dual";                 # BR/EDR + LE (default)
      FastConnectable = true;                  # Faster reconnect (slightly more power)
      Privacy = "device";                      # Better LE address resolution
      JustWorksRepairing = "always";           # Automatic re-pairing for "Just Works" devices
      ReconnectAttempts = 7;                   # Retry count for reconnect
      ReconnectIntervals = "1,2,4,8,16,32,64"; # Backoff strategy
      Plugins = "battery-poll";
      # Set a reasonable interval (e.g., 300 seconds = 5 minutes)
      PollInterval = 300;
    };
  };

  # https://wiki.archlinux.org/title/Bluetooth#Wake_from_suspend
  powerManagement.enable = true;
  services.udev.extraRules = ''
    # Enable wake from suspend for Bluetooth USB wireless class devices
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usb", \
      ATTR{bDeviceClass}=="e0", \
      ATTR{bDeviceProtocol}=="01", \
      ATTR{bDeviceSubClass}=="01", \
      ATTR{power/wakeup}="enabled"
  '';
}
