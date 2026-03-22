{
  config,
  pkgs,
  lib,
  ...
}:

let
  theme = if config.myTheme.preferDark then "Adwaita-dark" else "Adwaita";

  # Import user registry to get paths
  registry = import ../../users/registry.nix;
  hostname = config.networking.hostName;
  primaryUsername = registry.hosts.${hostname};
  userConfig = registry.users.${primaryUsername};
in
{

  # Display manager
  services.displayManager.gdm.enable = true;

  # Wayland compositor
  programs.niri.enable = true;

  # DankMaterialShell
  programs.dms-shell = {
    enable = true;

    systemd.enable = true;

    enableSystemMonitoring = true;
    enableClipboardPaste = true;
    enableDynamicTheming = true;
  };

  # Keyring
  services.gnome.gnome-keyring.enable = true;

  # Polkit
  security.polkit.enable = true;

  # File manager integration
  services.gvfs.enable = true;

  # Input devices
  services.libinput.enable = true;

  # Nvidia / AMD hybrid
  services.xserver.enable = true;
  services.xserver.videoDrivers = [
    "nvidia"
    "amdgpu"
  ];

  # Wayland compatibility
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # GTK defaults
  environment.etc."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=${theme}
    gtk-application-prefer-dark-theme=${if config.myTheme.preferDark then "1" else "0"}
    gtk-font-name=Inter 11
    gtk-monospace-font-name=Hack 11
  '';

  # XDG portals
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = [
      "gtk"
      "*"
    ];
  };

  # Touchpad gestures
  services.touchegg.enable = true;

  # Default touchegg config
  environment.etc."touchegg/touchegg.conf".text = ''
    <touchégg>

      <gesture type="SWIPE" fingers="3" direction="LEFT">
        <action type="COMMAND">
          niri msg action focus-workspace-right
        </action>
      </gesture>

      <gesture type="SWIPE" fingers="3" direction="RIGHT">
        <action type="COMMAND">
          niri msg action focus-workspace-left
        </action>
      </gesture>

    </touchégg>
  '';

  environment.etc."niri/config-extra.kdl".text = ''
    layout {
      show-window-previews true
      focus-ring true
      focus-follows-mouse true
    }

    binds {

      Mod+H { focus-column-left; }
      Mod+L { focus-column-right; }

      Mod+Shift+H { move-column-left; }
      Mod+Shift+L { move-column-right; }

      Super { show-workspace-overlay; }

    }
  '';

  environment.etc."niri/config.kdl".text = ''
    include "dms/binds.kdl"
    include "dms/colors.kdl"
    include "dms/layout.kdl"
    include "dms/cursor.kdl"
    include "dms/outputs.kdl"
    include "dms/windowrules.kdl"
    include "dms/alttab.kdl"
    include "config-extra.kdl"
  '';

  system.activationScripts.linkNiriConfig = {
  deps = [ "etc" ];
  text = ''
    mkdir -p ${userConfig.homeDirectory}/.config/niri
    # Remove dead symlink or old file first
    rm -f ${userConfig.homeDirectory}/.config/niri/config.kdl
    ln -sf /etc/niri/config.kdl ${userConfig.homeDirectory}/.config/niri/config.kdl
  '';
};

  systemd.user.services.mako = {
    description = "Mako notification daemon";
    after = [
      "graphical.target"
      "graphical-session.target"
    ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = ''
        mkdir -p ${userConfig.homeDirectory}/.config/mako
        exec ${pkgs.mako}/bin/mako
      '';
      Restart = "on-failure";
      Type = "simple";
    };
    wantedBy = [
      "graphical-session.target"
    ];
  };

  environment.etc."mako/config".text = ''
    font=Inter 10
    background-color=#1e1e2e
    text-color=#cdd6f4
    border-color=#89b4fa
    default-timeout=5000
  '';

  systemd.user.services.swayidle = {
    description = "Sway idle manager";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = ''
        ${pkgs.swayidle}/bin/swayidle -w \
          timeout ${toString (5 * 60)} '${pkgs.swaylock}/bin/swaylock -f' \
          timeout ${toString (30 * 60)} 'systemctl suspend' \
          before-sleep '${pkgs.swaylock}/bin/swaylock -f'
      '';
      Restart = "on-failure";
    };
  };

  # Useful desktop tools
  environment.systemPackages = with pkgs; [

    # screensaver
    swayidle
    swaylock

    # notification daemon
    mako

    # GTK themes
    adwaita-icon-theme
    adwaita-fonts
    gnome-themes-extra

    # clipboard
    wl-clipboard

    # screenshots
    grim
    slurp

    # screen lock
    swaylock

    # tools
    dconf-editor
    baobab
    file-roller

    # GTK appearance
    nwg-look

    # network tray
    networkmanagerapplet
  ];

  # Qt support
  qt.enable = true;

  # Network manager fix
  networking.networkmanager.settings.connectivity.interval = 0;

  environment.sessionVariables.NIXOS_XDG_OPEN_USE_PORTAL = "1";

}
