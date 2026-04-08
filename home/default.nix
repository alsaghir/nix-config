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

in

{
  imports = [
    ./gnome.nix
    ./ssh.nix
  ];

  programs.bash.enable = true;
  programs.direnv.enable = true;
  programs.direnv.enableZshIntegration = true;
  programs.direnv.nix-direnv.enable = true;
  programs.eza.enable = true;
  programs.eza.enableZshIntegration = true;
  programs.fastfetch.enable = true;
  programs.fd.enable = true;
  programs.firefox.enable = true;
  programs.fzf.enable = true;
  programs.fzf.enableZshIntegration = true;
  programs.ghostty.enable = true;
  programs.git.enable = true;
  programs.jq.enable = true;
  programs.k9s.enable = true;
  programs.lsd.enable = true;
  programs.lsd.enableZshIntegration = true;
  programs.nix-index.enable = true;
  programs.nix-index.enableZshIntegration = true;
  programs.nix-your-shell.nix-output-monitor.enable = true;
  programs.ptyxis.enable = true;
  programs.ripgrep-all.enable = true;
  programs.ripgrep.enable = true;
  programs.starship.enable = true;
  programs.starship.enableZshIntegration = true;
  programs.vesktop.enable = true;
  programs.vim.enable = true;
  programs.vscode.enable = true;
  programs.zoxide.enable = true;

  services.remmina.enable = true;

  programs.onlyoffice = {
    enable = true;
    package = onlyofficeQtScale1;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "cp"
        "history"
        "kind"
        "kubectl"
        "podman"
        "ssh"
        "ssh-agent"
        "sudo"
        "systemd"
        "eza"
      ];
    };

    initContent =
      let
        zshConfigEarlyInit = lib.mkOrder 500 ''
          echo "Early init"
          # source /etc/profile
        '';
        zshConfigBeforeCompletionInit = lib.mkOrder 550 ''echo "Before completion init"'';
        zshConfig = lib.mkOrder 1000 ''echo "General Config init"'';
        zshConfigLastToRun = lib.mkOrder 1500 ''
          echo "General Config init"

          # determinate-nixd completion (if installed)
          if command -v determinate-nixd >/dev/null 2>&1; then
            eval "$(determinate-nixd completion zsh)"
          fi

          # just completion (safe if just missing)
          if command -v just >/dev/null 2>&1; then
            eval "$(just --completions zsh)"
          fi

          echo "Last to run init"
        '';
      in
      lib.mkMerge [
        zshConfigEarlyInit
        zshConfigBeforeCompletionInit
        zshConfig
        zshConfigLastToRun
      ];

  };

   programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep 5";
    };
  };

  home.packages = with pkgs; [
    jetbrains-toolbox

    gemini-cli
    biglybt
  
    kubectl
    
    antigravity
    mission-center

    adwaita-fonts
    adwaita-icon-theme
    microsoft-edge
    smplayer
    bitwarden-desktop
    krita
    vlc
    
    slack
    libreoffice
    
    kdePackages.konsole
    gradia
  ];

}
