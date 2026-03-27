{ pkgs, lib, ... }:

let

  mkQtScaledApp =
    {
      pkg,
      scale ? "1",
      fontDpi ? "96",
    }:
    pkgs.symlinkJoin {
      name = "${lib.getName pkg}-qt-scale-${builtins.replaceStrings [ "." ] [ "_" ] scale}";
      paths = [ pkg ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        if [ -d "$out/bin" ]; then
          for f in $out/bin/*; do
            [ -f "$f" ] && [ -x "$f" ] || continue
            wrapProgram "$f" --set QT_SCALE_FACTOR ${scale} --set QT_FONT_DPI ${fontDpi}
          done
        fi

        if [ -d "$out/share/applications" ]; then
        for desktop in "$out/share/applications"/*.desktop; do
          [ -f "$desktop" ] || continue
          # Dereference the symlink so we can edit it
          cp --remove-destination "$(readlink -f "$desktop")" "$desktop"
          # Repoint Exec= from the original pkg store path to our wrapped $out/bin
          substituteInPlace "$desktop" --replace-warn "${pkg}/bin/" "$out/bin/"
        done
      fi
      '';
    };

  onlyofficeQtScale1 = mkQtScaledApp {
    pkg = pkgs.onlyoffice-desktopeditors;
    scale = "1";
    fontDpi = "96";
  };

  basePackages = with pkgs; [
    jetbrains-toolbox
    bash
    usbutils
    mesa-demos
    vulkan-tools
    fastfetch
    unzip
    just
    vim
    libinput

    eza
    lsd

    ncdu
    dust

    bat
    ripgrep
    fd

    gemini-cli

    nixfmt
    statix
    deadnix
    nix-output-monitor
    nvd
    nix-diff
    nix-tree
    nix-index
    nil

    biglybt
    k9s
    kubectl
    remmina
    vscode
    antigravity
    mission-center

    adwaita-fonts
    adwaita-icon-theme
    microsoft-edge
    smplayer
    bitwarden-desktop
    krita
    vlc
    vesktop
    slack
    libreoffice
    onlyofficeQtScale1
    ptyxis
    ghostty
  ];

in
{
  environment.systemPackages = basePackages;
  programs.firefox.enable = true;
  programs.evolution = {
    enable = true;
    plugins = with pkgs; [
      evolution-ews
    ];
  };

}
