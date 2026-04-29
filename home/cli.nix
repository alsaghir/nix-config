{
  pkgs,
  lib,
  inputs,
  ...
}:

{

  programs.bash.enable = true;
  programs.direnv.enable = true;
  programs.direnv.enableZshIntegration = true;
  programs.direnv.nix-direnv.enable = true;
  programs.eza.enable = true;
  programs.eza.enableZshIntegration = true;
  programs.fastfetch.enable = true;
  programs.fd.enable = true;
  programs.fzf.enable = true;
  programs.fzf.enableZshIntegration = true;
  programs.git.enable = true;
  programs.jq.enable = true;
  programs.lsd.enable = false;
  programs.lsd.enableZshIntegration = false;
  programs.nix-index.enable = true;
  programs.nix-index.enableZshIntegration = true;
  programs.ripgrep-all.enable = true;
  programs.ripgrep.enable = true;
  programs.starship.enable = true;
  programs.starship.enableZshIntegration = true;
  programs.vim.enable = true;

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
    usbutils
    mesa-demos
    vulkan-tools
    unzip
    just
    
    libinput
    openssh

    safe-rm

    ncdu
    dust

    nixfmt
    statix
    deadnix
    nvd
    nix-diff
    nix-tree
    nil

    gemini-cli
    kubectl
    adwaita-fonts
  ];

}
