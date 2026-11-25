# Terminal environment: zsh (or bash, see bashHook), CLI tools, direnv, nh.
# Where an OS image owns ~/.bashrc, bashHook.execZsh keeps that file as the login
# environment and continues every interactive terminal in zsh.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixConfig.cli;
  bash = config.programs.bash;
  hookFile = ".config/home-manager/bash-hook.sh";
  marker = "home-manager bash hook";
  handoffVar = "HM_ZSH_HANDOFF";
in
{
  options.nixConfig.cli = {
    enable = lib.mkEnableOption "the terminal environment (zsh, CLI tools, nh)";

    bashHook.enable = lib.mkEnableOption ''
      bash for a ~/.bashrc owned by something else (e.g. an OS image whose tools edit it).
      Home Manager manages neither bash nor zsh files; the `programs.bash` configuration
      (bashrcExtra, aliases, initExtra, which tool integrations fill) is rendered to
      ~/${hookFile} instead, and one guarded line sourcing it is appended to ~/.bashrc'';

    bashHook.execZsh = lib.mkEnableOption ''
      zsh for interactive terminals on top of bashHook: ~/.bashrc still runs first, so
      everything it exports reaches zsh, then the hook replaces the shell with zsh
      (configured as on any other host). Lines appended to ~/.bashrc after the hook line
      do not run in interactive shells. A shell started from zsh (`bash`, `nix develop`)
      stays bash, since ${handoffVar} is already set'';

    blesh.enable = lib.mkEnableOption "ble.sh (bash line editor: autosuggestions, syntax highlighting)";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        programs = {
          bash.enable = !cfg.bashHook.enable;
          bat.enable = true;
          btop.enable = true;
          direnv = {
            enable = true;
            nix-direnv.enable = true;
          };
          # icons/extraOptions become an `eza` alias, so they apply to every eza alias (ls, ll, lt, ...)
          eza = {
            enable = true;
            icons = "auto";
            extraOptions = [ "--group-directories-first" ];
          };
          fastfetch.enable = true;
          fd.enable = true;
          fzf.enable = true;
          git.enable = true;
          jq.enable = true;
          nh = {
            enable = true;
            clean = {
              enable = true;
              extraArgs = "--keep 5";
            };
          };
          nix-index.enable = true;
          ripgrep.enable = true;
          ripgrep-all.enable = true;
          starship.enable = true;
          zoxide.enable = true;
          zsh = {
            enable = !cfg.bashHook.enable || cfg.bashHook.execZsh;
            enableCompletion = true;
            autosuggestion.enable = true;
            syntaxHighlighting.enable = true;
            dotDir = "${config.xdg.configHome}/zsh";

            oh-my-zsh = {
              enable = true;
              theme = "robbyrussell";
              plugins = [
                "git"
                "cp"
                "history"
                "kind"
                "kubectl"
                "helm"
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

                  # AI Keys
                  if [ -r "$AI_ENV_FILE" ]; then
                    set -a
                    source "$AI_ENV_FILE"
                    set +a
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
        };

        # Overrides the module's mkDefault `ls = "eza"` in bash and zsh
        home.shellAliases.ls = "eza -laho";

        home.packages = with pkgs; [
          # Basics
          usbutils
          unzip
          just

          openssh

          # rm wrapper that refuses to delete protected paths
          safe-rm

          # Disk usage
          ncdu
          dust

          # Nix: formatting, linting, diffing generations and closures
          nixfmt
          statix
          deadnix
          nvd
          nix-diff
          nix-tree
        ];
      }

      (lib.mkIf cfg.blesh.enable {
        # Loaded before anything binds keys, attached after everything else (prompt included;
        # integrations go up to order 2000, e.g. zoxide).
        programs.bash.initExtra = lib.mkMerge [
          (lib.mkOrder 50 ''. "${pkgs.blesh}/share/blesh/ble.sh" --noattach'')
          (lib.mkOrder 3000 ''[[ -n "''${BLE_VERSION-}" ]] && ble-attach'')
        ];
      })

      (lib.mkIf cfg.bashHook.enable {
        # Same layout as Home Manager's own ~/.bashrc (programs/bash.nix), plus what its
        # ~/.profile would provide, since login shells read the unmanaged files only.
        home.file.${hookFile}.text = ''
          # Managed by Home Manager (nixConfig.cli.bashHook). Sourced from ~/.bashrc.
          # Moved to the front even when already present: the image may put copies of the
          # same tools (kubectl, az, gh, ...) in /usr/bin, /usr/local/bin or ~/.local/bin.
          __hm_bin="${config.home.profileDirectory}/bin"
          PATH=":$PATH:"
          while [[ $PATH == *":$__hm_bin:"* ]]; do PATH="''${PATH/":$__hm_bin:"/:}"; done
          PATH="''${PATH#:}"
          PATH="''${PATH%:}"
          export PATH="$__hm_bin''${PATH:+:$PATH}"
          unset __hm_bin
          . "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh"

          ${bash.bashrcExtra}

          [[ $- == *i* ]] || return 0
          ${lib.optionalString cfg.bashHook.execZsh ''

            # bashHook.execZsh: only the first interactive shell of a terminal, and only on a tty.
            if [[ -z "''${${handoffVar}-}" && -t 0 && -t 1 ]]; then
              export ${handoffVar}=1
              exec ${lib.getExe config.programs.zsh.package}
            fi
          ''}
          if [[ ! -v BASH_COMPLETION_VERSINFO ]]; then
            . "${pkgs.bash-completion}/etc/profile.d/bash_completion.sh"
          fi

          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (k: v: "alias -- ${k}=${lib.escapeShellArg v}") bash.shellAliases
          )}

          ${bash.initExtra}
        '';

        # Appends once, never rewrites: the file's owner may edit it (e.g. `sed -i`) at any time.
        home.activation.bashHook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          bashrc="$HOME/.bashrc"
          if [[ ! -e "$bashrc" ]] || ${lib.getExe pkgs.gnugrep} -qF "# >>> ${marker} >>>" "$bashrc"; then
            :
          elif [[ -w "$bashrc" ]]; then
            run tee -a "$bashrc" >/dev/null <<'EOF'

          # >>> ${marker} >>>
          [ -r "$HOME/${hookFile}" ] && . "$HOME/${hookFile}"
          # <<< ${marker} <<<
          EOF
          else
            warnEcho "$bashrc is not writable; add: . \"\$HOME/${hookFile}\""
          fi
        '';
      })
    ]
  );
}
