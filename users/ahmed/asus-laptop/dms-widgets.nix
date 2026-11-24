# ahmed's DMS desktop widgets on asus-laptop (home/desktop/dms.nix). Positions live in
# session.json, keyed by the widget ids from settings.json. syncPositionAcrossScreens stores one
# "_synced" position, as fractions of the screen, used on every output, including ones not in
# hosts/asus-laptop/displays.nix.
{ config, ... }:
let
  clock = "dw_1794843642879_yxovj2l9a";
  systemMonitor = "dw_1794843747110_p3mp8c4pv";

  # Top-right corner: offsets (px) from the right/top edge, as laid out on DP-1.
  reference = config.nixConfig.displays.DP-1;
  topRight = size: rightOffset: {
    _synced = size // {
      x = rightOffset / (reference.width * 1.0);
      y = 60 / (reference.height * 1.0);
      anchorX = "end";
    };
  };

  common = {
    transparency = 0.8;
    colorMode = "secondary";
    customColor = "#ffffff";
    displayPreferences = [ "all" ];
    syncPositionAcrossScreens = true;
  };
in
{
  programs.dank-material-shell = {
    settings.desktopWidgetInstances = [
      {
        id = clock;
        widgetType = "desktopClock";
        name = "Clock";
        enabled = true;
        config = common // {
          style = "analog";
          showDate = true;
          showAnalogNumbers = true;
          showAnalogSeconds = false;
        };
      }
      {
        id = systemMonitor;
        widgetType = "systemMonitor";
        name = "System Monitor";
        enabled = true;
        config = common // {
          showHeader = true;
          showCpu = true;
          showCpuGraph = true;
          showCpuTemp = true;
          showGpuTemp = true;
          gpuPciId = "10de:249d"; # NVIDIA dGPU, from `lspci -nn`
          showMemory = true;
          showMemoryGraph = true;
          showNetwork = true;
          showNetworkGraph = true;
          showDisk = false;
          showTopProcesses = true;
          topProcessCount = 10;
          topProcessSortBy = "cpu";
          layoutMode = "auto";
          graphInterval = 300;
        };
      }
    ];

    session = {
      desktopWidgetInstancePositions = {
        ${clock} = topRight {
          width = 200;
          height = 200;
        } 110;
        ${systemMonitor} = topRight {
          width = 320;
          height = 480;
        } 350;
      };
      desktopWidgetGridSettings.DP-1 = {
        enabled = true;
        size = 30;
      };
    };
  };
}
