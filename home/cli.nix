# Terminal environment: zsh (or bash, see bashHook), CLI tools, direnv, nh.
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
in
{
  options.nixConfig.cli = {
    enable = lib.mkEnableOption "the terminal environment (zsh, CLI tools, nh)";

    bashHook.enable = lib.mkEnableOption ''
      bash for a ~/.bashrc owned by something else (e.g. an OS image whose tools edit it).
      Home Manager manages neither bash nor zsh files; the `programs.bash` configuration
      (bashrcExtra, aliases, initExtra, which tool integrations fill) is rendered to
      ~/${hookFile} instead, and one guarded line sourcing it is appended to ~/.bashrc'';

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
            enableZshIntegration = true;
            nix-direnv.enable = true;
          };
          # icons/extraOptions become an `eza` alias, so they apply to every eza alias (ls, ll, lt, ...)
          eza = {
            enable = true;
            enableZshIntegration = true;
            icons = "auto";
            extraOptions = [ "--group-directories-first" ];
          };
          fastfetch.enable = true;
          fd.enable = true;
          fzf = {
            enable = true;
            enableZshIntegration = true;
          };
          git.enable = true;
          jq.enable = true;
          nh = {
            enable = true;
            clean = {
              enable = true;
              extraArgs = "--keep 5";
            };
          };
          nix-index = {
            enable = true;
            enableZshIntegration = true;
          };
          ripgrep.enable = true;
          ripgrep-all.enable = true;
          starship = {
            enable = true;
            enableZshIntegration = true;
          };
          zoxide.enable = true;
          zsh = {
            enable = !cfg.bashHook.enable;
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
          __hm_profile="${config.home.profileDirectory}"
          case ":$PATH:" in
            *":$__hm_profile/bin:"*) ;;
            *) export PATH="$__hm_profile/bin:$PATH" ;;
          esac
          unset __hm_profile
          . "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh"

          ${bash.bashrcExtra}

          [[ $- == *i* ]] || return 0

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
