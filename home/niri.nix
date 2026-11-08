{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.nixConfig) displays;
  connectors = internal: builtins.attrNames (lib.filterAttrs (_: d: d.internal == internal) displays);
  internals = connectors true;
  externals = connectors false;
in
{

  services.gnome-keyring.enable = true;

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # Written to ~/.config/environment.d, read by the systemd user manager at login.
  # greetd's login doesn't export XDG_SESSION_CLASS (GDM did), and localsearch-3.service has
  # ConditionEnvironment=XDG_SESSION_CLASS=user, so without this the indexer never starts.
  systemd.user.sessionVariables.XDG_SESSION_CLASS = "user";

  programs.niri = {
    enable = true;
    package = pkgs.niri;
    settings = {
      # xwayland-satellite: niri (>= 25.08) spawns it on demand; it only needs to be in PATH as a package
      input = {
        focus-follows-mouse.enable = true;
        keyboard = {
          numlock = true;
          # English + Arabic; switch with Mod+Shift+Space (bind below) or click the DMS bar widget.
          # Not an xkb grp:* toggle: Alt+Shift would also fire on Alt+Shift+Arrow (window moves).
          #
          # Names come from xkeyboard-config (a libxkbcommon dependency, pinned via nixpkgs).
          # `localectl list-x11-keymap-*` doesn't work on NixOS (no /etc/X11/xkb); read the list directly:
          #   X=$(nix build nixpkgs#xkeyboard-config --print-out-paths --no-link)/share/X11/xkb/rules/evdev.lst
          #   awk '/^! layout/{f=1;next} /^!/{f=0} f' $X | less                # all layouts
          #   awk '/^! variant/{f=1;next} /^!/{f=0} f && $2=="ara:"' $X        # variants of one layout
          # Preview on a drawn keyboard (layout or layout+variant):
          #   nix run nixpkgs#gnome-tecla -- ara
          #   nix run nixpkgs#gnome-tecla -- ara+mac
          # Arabic variants: basic (default when empty: standard QWERTY-based/Windows Arabic, what
          # Arabic-printed laptop keys use; Q=ض A=ش Z=ئ), digits, azerty (French-keyboard base),
          # azerty_digits, buckwalter, mac, mac-phonetic, olpc. Source: symbols/ara in the same package.
          xkb = {
            layout = "us,ara";
            # One entry per layout, by position; "" = the layout's default (its "basic" section).
            variant = ",basic";
          };
        };
      };
      binds."Mod+Shift+Space" = {
        action.switch-layout = "next";
        hotkey-overlay.title = "Switch Keyboard Layout";
      };
      # Generated from nixConfig.displays (hosts/<host>/displays.nix via users/registry.nix).
      # To let DMS manage monitors instead (Settings → Displays + profiles):
      # remove this line and services.kanshi below, uncomment "outputs" in home/dms.nix,
      # and set programs.dank-material-shell.settings.displayProfileAutoSelect = true.
      outputs = lib.mapAttrs (
        _: d:
        {
          mode = { inherit (d) width height refresh; };
          position = { inherit (d) x y; };
        }
        // lib.optionalAttrs (d.scale != null) { inherit (d) scale; }
      ) displays;

      # QT_QPA_PLATFORMTHEME comes from the qt block in home/dms.nix.
      environment = {
        QT_WAYLAND_DECORATION = "adwaita";
      };

    };
  };

  # Runtime output profiles, picked by which monitors are connected (exact set match).
  # docked: every external connected → internal panels off. mobile: internals only.
  # Only toggles internals; modes/positions stay in programs.niri.settings.outputs above.
  # Enabled only on hosts that have both internal and external displays.
  # Session-only: the greeter is a separate niri instance, so the panel stays on at login.
  # Remove when using DMS display profiles (see the outputs comment above); never run both.
  services.kanshi = {
    enable = internals != [ ] && externals != [ ];
    settings = [
      {
        profile.name = "docked";
        profile.outputs =
          map (criteria: { inherit criteria; }) externals
          ++ map (criteria: {
            inherit criteria;
            status = "disable";
          }) internals;
      }
      {
        # Without this, unplugging the externals would leave the panel disabled (black screen).
        profile.name = "mobile";
        profile.outputs = map (criteria: {
          inherit criteria;
          status = "enable";
        }) internals;
      }
    ];
  };

}
