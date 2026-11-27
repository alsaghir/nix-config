# Preferences shared by the niri shells; home/desktop/dms.nix and home/desktop/noctalia.nix each
# translate them into their own settings format.
{
  fontFamily = "Inter";
  clock12h = true;

  location = {
    name = "القاهرة";
    # Strings: Nix prints floats with 6 significant digits.
    latitude = "30.0443879";
    longitude = "31.2357257";
  };

  wallpaper = {
    default = "Pictures/wallpapers/1351306.png"; # relative to the home directory
    cycleSeconds = 3 * 60;
  };

  bar = {
    position = "right";
    opacity = 0.7;
    fontScale = 1.4;
    padding = 16;
    outlineThickness = 2;
  };

  dock = {
    position = "left";
    iconSize = 36;
    itemSpacing = 4;
    # App ids as DMS records them when pinning (`dms ipc call settings dumpSession`); they are the
    # apps' StartupWMClass or desktop ids, which Noctalia matches too.
    pinned = [
      "firefox"
      "com.mitchellh.ghostty"
      "github-copilot-app"
      "BiglyBT Extreme Mod"
      "microsoft-edge"
      "code"
      "thunderbird"
    ];
  };

  # Seconds; 0 = never. screenOffLocked: monitors off this long after locking.
  idle = {
    ac = {
      lock = 5 * 60;
      screenOff = 10 * 60;
      suspend = 30 * 60;
      screenOffLocked = 60;
    };
    battery = {
      lock = 60;
      screenOff = 60;
      suspend = 15 * 60;
      screenOffLocked = 30;
    };
  };
}
