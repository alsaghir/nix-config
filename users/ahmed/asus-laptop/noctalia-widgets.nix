# ahmed's Noctalia desktop widgets on asus-laptop (home/desktop/noctalia.nix), ported from
# dms-widgets.nix. Noctalia places each widget on one output, so they sit on DP-1 (the main
# monitor; DMS repeated them on every screen). Moving one in edit mode saves to the state file,
# which overrides this.
{ config, ... }:
let
  output = "DP-1";
  reference = config.nixConfig.displays.${output};

  # Same corner as the DMS layout: a box whose top-right is `right`/`top` px from the screen's.
  topRight =
    {
      width,
      height,
      right,
      top,
    }:
    {
      inherit output;
      cx = reference.width - right - width / 2.0;
      cy = top + height / 2.0;
      box_width = width;
      box_height = height;
    };

  # DMS's single system-monitor card becomes three stacked two-line graphs.
  graph =
    index: stat: stat2:
    topRight {
      width = 320;
      height = 150;
      right = 350;
      top = 60 + index * 160;
    }
    // {
      type = "sysmon";
      settings = {
        inherit stat stat2;
        display = "graph";
      };
    };
in
{
  programs.noctalia.settings.desktop_widgets = {
    enabled = true;
    widget = {
      clock =
        topRight {
          width = 200;
          height = 200;
          right = 110;
          top = 60;
        }
        // {
          type = "clock";
          settings = {
            clock_style = "analog";
            show_seconds = false;
          };
        };
      cpu = graph 0 "cpu_usage" "cpu_temp";
      memory = graph 1 "ram_pct" "gpu_temp";
      network = graph 2 "net_rx" "net_tx";
    };
  };
}
