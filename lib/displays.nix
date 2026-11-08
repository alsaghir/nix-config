# nixConfig.displays: a host's monitor layout, declared once in the registry
# (users/registry.nix → hosts.<host>.displays) and injected into both NixOS and
# Home Manager by lib/default.nix. Pure option declaration, valid in either module system.
# Consumers: home/niri.nix (outputs, kanshi), home/dms.nix (wallpaper cycling),
# nixos/desktop/dms.nix (greeter layout).
{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.nixConfig.displays = mkOption {
    default = { };
    description = "Monitors of this host, keyed by connector name (e.g. eDP-1, as in `niri msg outputs`).";
    type = types.attrsOf (
      types.submodule {
        options = {
          width = mkOption { type = types.ints.positive; };
          height = mkOption { type = types.ints.positive; };
          refresh = mkOption {
            type = types.nullOr types.float;
            default = null;
            description = "Hz; null lets the compositor pick the highest.";
          };
          x = mkOption { type = types.int; };
          y = mkOption {
            type = types.int;
            description = "Logical pixels: a neighbour's size is divided by its scale.";
          };
          scale = mkOption {
            type = types.nullOr types.float;
            default = null;
            description = "null lets the compositor pick.";
          };
          internal = mkOption {
            type = types.bool;
            default = false;
            description = "Built-in panel: turned off while all external displays are connected.";
          };
        };
      }
    );
  };
}
