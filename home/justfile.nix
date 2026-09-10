{ config, lib, pkgs, ... }:
with lib;
{
  options.justfile.recipes = mkOption {
    type = types.lines;
    default = "";
    description = "Accumulated recipes for the global justfile";
  };

  config = {
    justfile.recipes = ''
      # Global justfile recipes
      default:
          @just --list

    '';

    xdg.configFile."just/justfile".text = config.justfile.recipes;
  };
}