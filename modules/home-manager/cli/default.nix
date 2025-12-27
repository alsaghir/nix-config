{ pkgs, lib, ... }:
{
  imports = [
    ./ssh.nix
  ];
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
        "eza"
        "fzf"
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
          echo "Last to run init"
          # Mise activation for zsh
          # eval "$(mise activate zsh)"
          # Nix auto-completion if you have it
          if command -v determinate-nixd >/dev/null 2>&1; then
            eval "$(determinate-nixd completion zsh)"
          fi
        '';
      in
      lib.mkMerge [
        zshConfigEarlyInit
        zshConfigBeforeCompletionInit
        zshConfig
        zshConfigLastToRun
      ];
  };

  # direnv with nix-direnv
  # direnv watches your .envrc files and loads/unloads environment variables automatically
  # nix-direnv allows direnv to work seamlessly with Nix projects via caching, much faster
  # without nix-direnv, direnv would have to build the Nix expressions every time it loads an .envrc
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # Proper starship via HM
  programs.starship.enable = true;

  # Optional nice CLI tools
  programs.zoxide.enable = true;
  programs.fzf.enable = true;

  programs.git.enable = true;

  # Shell and small conveniences
  home.shellAliases = {
    idea = "(/home/ahmed/.local/share/JetBrains/Toolbox/apps/intellij-idea/bin/idea . > /dev/null 2>&1 & disown)";
    rm = "rm -i";
    gpustat = "nvidia-smi";
    offload-gl = "__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo -B | egrep 'OpenGL (vendor|renderer)'";
  };
}
