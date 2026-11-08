# `justfile.recipes`: modules append recipes; the result is ~/.config/just/justfile (alias `j`).
{ config, lib, ... }:
{
  options.justfile.recipes = lib.mkOption {
    type = lib.types.lines;
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
