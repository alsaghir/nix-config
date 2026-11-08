{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.nixConfig.desktop.fonts.enable = lib.mkEnableOption "desktop fonts and fontconfig defaults";

  config = lib.mkIf config.nixConfig.desktop.fonts.enable {
    fonts.fontDir.enable = true;
    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        nerd-fonts.hack
        nerd-fonts.symbols-only
        noto-fonts-color-emoji
        hack-font
        adwaita-fonts
        inter
        inter-nerdfont
      ];
      fontconfig.defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [
          "Inter"
          "Symbols Nerd Font"
          "Symbols Nerd Font Mono"
        ];
        monospace = [
          "Hack Nerd Font"
          "Symbols Nerd Font"
          "Hack"
        ];
      };
    };
  };
}
