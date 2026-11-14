# Compositor-agnostic desktop base: audio, input, removable media, Flatpak, fonts.
# Enabled by each desktop (nixos/desktop/niri.nix, …), rarely by hosts directly.
{ config, lib, ... }:
{
  options.nixConfig.desktop.common.enable = lib.mkEnableOption "the compositor-agnostic desktop base";

  config = lib.mkIf config.nixConfig.desktop.common.enable {
    nixConfig.desktop.fonts.enable = lib.mkDefault true;

    i18n.inputMethod = {
      enable = true;
      type = "ibus";
    };

    services.flatpak.enable = true;
    services.libinput.enable = true;

    # For trash support in file managers
    services.gvfs.enable = true;
    # Mounting USB drives from the file manager (gvfs's udisks2 volume monitor); explicit, not left to another module
    services.udisks2.enable = true;

    # Audio (low-latency PipeWire)
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # Optional low-latency tuning; remove if undesired
      extraConfig.pipewire."92-low-latency" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 256;
          "default.clock.min-quantum" = 128;
          "default.clock.max-quantum" = 1024;
        };
      };
    };
  };
}
