{ pkgs, lib, ... }:
{
  # Zsh
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
      ];
    };
    # Note: Your initContent is fine, but can be simplified if ordering
    # of the 'echo' commands isn't critical.
    initContent = ''
      echo "Early init"
      echo "Before completion init"
      echo "General Config init"
      echo "Last to run init"
      # Mise activation for zsh
      # eval "$(mise activate zsh)"
      # Nix auto-completion if you have it
      if command -v determinate-nixd >/dev/null 2>&1; then
        eval "$(determinate-nixd completion zsh)"
      fi
    '';
  };

  # Proper starship via HM
  programs.starship.enable = true;

  # Optional nice CLI tools
  programs.zoxide.enable = true;
  programs.fzf.enable = true;

  programs.git.enable = true;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "github" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        extraOptions = {
          AddKeysToAgent = "yes";
          IdentitiesOnly = "yes";
          PreferredAuthentications = "publickey";
        };
      };
      "*" = {
        identityFile = "~/.ssh/id_ed25519";
        extraOptions = {
          AddKeysToAgent = "yes";
          IdentitiesOnly = "yes";
        };
        user = "git";
      };
    };
  };

  # Shell and small conveniences
  home.shellAliases = {
    gpustat = "nvidia-smi";
    offload-gl = "__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo -B | egrep 'OpenGL (vendor|renderer)'";
  };
}
