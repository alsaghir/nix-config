{ config, pkgs, pkgsUnstable ? null, lib, ... }:
{
  home.username = "ahmed";
  home.homeDirectory = "/home/ahmed";
  
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

  # Proper starship via HM (adds the init line automatically)
  programs.starship.enable = true;

  # Optional nice CLI tools
  programs.zoxide.enable = true;
  programs.fzf.enable = true;

  # User-level packages (not strictly needed system-wide)
  home.packages = with pkgs; [
    mesa-demos
    vulkan-tools
    fastfetch

    pkgsUnstable.mise

    statix
    deadnix
    alejandra
    nix-output-monitor
    nvd
    nix-diff
    nix-tree
    nix-index
  ];

  programs.vscode = {
    enable = true;
    package = pkgs.vscode; # or pkgs.vscodium if you prefer the FOSS build
    # Manage extensions with Nix (examples):
    # extensions = with pkgs.vscode-extensions; [
    #   ms-python.python
    #   ms-vscode.cpptools
    #   rust-lang.rust-analyzer
    # ];
    # User settings example:
    # userSettings = {
    #   "editor.fontLigatures" = true;
    #   "terminal.integrated.inheritEnv" = true;
    # };
  };

  programs.ssh = {
  enable = true;
  extraConfig = ''
    Host github
      HostName github.com
      User git
      IdentityFile ~/.ssh/id_ed25519
      AddKeysToAgent yes
      IdentitiesOnly yes
      PreferredAuthentications publickey

    Host *
      AddKeysToAgent yes
      IdentityFile ~/.ssh/id_ed25519
      IdentitiesOnly yes
      User git
  '';
};

  # Shell and small conveniences
  home.shellAliases = {
    gpustat = "nvidia-smi";
    offload-gl = "__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo -B | egrep 'OpenGL (vendor|renderer)'";
  };

  programs.git.enable = true;

  # Set HM state version (match current release; do not bump casually)
  home.stateVersion = "25.05";
}
