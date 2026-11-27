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
      # mkBefore: desktops may append their own defaults; ours stay first.
      fontconfig.defaultFonts = {
        serif = lib.mkBefore [ "Noto Serif" ];
        sansSerif = lib.mkBefore [
          "Inter"
          "Symbols Nerd Font"
          "Symbols Nerd Font Mono"
        ];
        monospace = lib.mkBefore [
          "Hack Nerd Font"
          "Symbols Nerd Font"
          "Hack"
        ];
      };
    };
  };
}
