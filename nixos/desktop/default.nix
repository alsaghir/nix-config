{ lib, ... }:
{
  imports = [
    ./gnome.nix
    ./fonts.nix
  ];

  options.myTheme = {
    preferDark = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to use dark theme variants";
    };
  };
}
