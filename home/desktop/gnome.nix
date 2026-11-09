# GNOME session settings (dconf) and Shell extensions. The desktop itself comes from the NixOS
# side (nixos/desktop/gnome.nix); this is the per-user layer. Tuned for GNOME reached over RDP:
# no animations (smoother stream), no idle blanking or screen lock (RDP gate + GDM already ask
# for passwords), no laptop power/battery settings. Resolution follows the RDP client window.
{
  lib,
  pkgs,
  config,
  ...
}:
{
  options.nixConfig.desktop.gnome.enable = lib.mkEnableOption "GNOME session settings and extensions";

  config = lib.mkIf config.nixConfig.desktop.gnome.enable {
    # Installs each extension and lists it in org/gnome/shell enabled-extensions.
    programs.gnome-shell = {
      enable = true;
      extensions = map (package: { inherit package; }) (
        with pkgs.gnomeExtensions;
        [
          advanced-alttab-window-switcher
          appindicator
          clipboard-indicator
          paperwm
          tophat
        ]
      );
    };

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        enable-animations = false;
        clock-format = "12h";
        locate-pointer = true;
        font-hinting = "none";
      };

      "org/gtk/settings/file-chooser".clock-format = "12h";

      "org/gnome/desktop/session".idle-delay = lib.gvariant.mkUint32 0;
      "org/gnome/desktop/screensaver".lock-enabled = false;
      "org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-type = "nothing";

      "org/gnome/desktop/wm/preferences".button-layout = "appmenu:minimize,maximize,close";

      # Alt+Tab switches windows, Super+Tab applications, Alt/Super+` windows of one app.
      "org/gnome/desktop/wm/keybindings" = {
        switch-windows = [ "<Alt>Tab" ];
        switch-windows-backward = [ "<Shift><Alt>Tab" ];
        switch-applications = [ "<Super>Tab" ];
        switch-applications-backward = [ "<Shift><Super>Tab" ];
        switch-group = [
          "<Alt>Above_Tab"
          "<Super>Above_Tab"
        ];
        switch-group-backward = [
          "<Shift><Alt>Above_Tab"
          "<Shift><Super>Above_Tab"
        ];
      };

      "org/gnome/shell/keybindings" = {
        toggle-message-tray = [ "<Super>m" ]; # GNOME's alternate default; Super+V is PaperWM's
        toggle-overview = [ "<Super>s" ];
      };

      # Log Out always in the menu: log out (not just disconnect) before a switch, see
      # nixos/desktop/gnome.nix.
      "org/gnome/shell".always-show-log-out = true;

      "org/gnome/shell/extensions/advanced-alt-tab-window-switcher".win-switcher-popup-filter = 1;

      "org/gnome/shell/extensions/paperwm" = {
        disable-topbar-styling = true;
        winprops = [
          (builtins.toJSON {
            wm_class = "jetbrains-toolbox";
            title = "";
            scratch_layer = false;
            preferredWidth = "101%";
          })
        ];
      };

      # PaperWM's own alt-tab and workspace bindings would take the keys set above.
      "org/gnome/shell/extensions/paperwm/keybindings" = {
        live-alt-tab = [ "" ];
        live-alt-tab-backward = [ "" ];
        previous-workspace = [ "" ];
        previous-workspace-backward = [ "" ];
      };
    };

    home.packages = with pkgs; [
      dconf-editor
      gnome-tweaks
      refine
    ];
  };
}
