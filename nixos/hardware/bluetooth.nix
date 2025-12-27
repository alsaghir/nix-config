{ config, pkgs, ... }:
{
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  # Explicitly install BlueZ tools (bluetoothctl, etc.) only when BT is enabled.
  hardware.bluetooth.package = pkgs.bluez;
  
  services.upower.enable = true;

  # BlueZ main.conf settings to favor LE/HOGP stability
  hardware.bluetooth.settings = {
    General = {
      Experimental = true;                     # Extra plugins (set false if unstable)
      ControllerMode = "dual";                 # BR/EDR + LE (default)
      FastConnectable = true;                  # Faster reconnect (slightly more power)
      Privacy = "device";                      # Better LE address resolution
      JustWorksRepairing = "always";           # Automatic re-pairing for "Just Works" devices
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
