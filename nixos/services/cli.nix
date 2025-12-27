{
  pkgs,
  lib,
  config,
  ...
}:

{
  # Zsh with Oh-My-Zsh, same plugins and init content as HM
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    ohMyZsh = {
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

    # Runs for all shells (keep minimal; no interactive-only stuff here)
    shellInit = ''
      echo "Early init"
      # Put only lightweight exports or path tweaks here
      # Avoid interactive prompts or completion here
    '';

    # Runs only for login shells
    loginShellInit = ''
      echo "Before completion init"
      # If you need it:
      # source /etc/profile
    '';

    # Runs only for interactive shells (your main config)
    interactiveShellInit = ''
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

    # Not needed because you use starship:
    # promptInit = "...";
  };

  # direnv + nix-direnv
  programs.direnv.enable = true;
  programs.direnv.enableZshIntegration = true;
  programs.direnv.nix-direnv.enable = true;

  # Starship prompt
  programs.starship.enable = true;

  # CLI conveniences
  programs.zoxide.enable = true;
  programs.git.enable = true;

  # Shell aliases (system-wide)
  environment.shellAliases = {
    j = "just --justfile ~/.config/just/justfile";
    rm = "rm -i";
    gpustat = "nvidia-smi";
    offload-gl = "__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo -B | egrep 'OpenGL (vendor|renderer)'";
  };
}
