{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

let
  fromGitHub =
    ref: repo:
    pkgs.vimUtils.buildVimPlugin {
      pname = "${lib.strings.sanitizeDerivationName repo}";
      version = ref;
      src = builtins.fetchGit {
        url = "https://github.com/${repo}.git";
        ref = ref;
      };
    };
in

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
  programs.vim.enable = false;
  programs.vim.defaultEditor = true;

  programs.antigravity-cli.enable = true;
  programs.aichat = {
    enable = true;
    settings = {
      model = "gemini:gemini-2.5-flash";
      stream = true;
      save = true;
      highlight = true;
      keybindings = "vi";

      clients = [
        {
          type = "gemini";
          api_base = "https://generativelanguage.googleapis.com/v1beta";
        }
        {
          type = "openai-compatible";
          name = "deepseek";
          api_base = "https://api.deepseek.com";
        }
        {
          type = "openai-compatible";
          name = "groq";
          api_base = "https://api.groq.com/openai/v1";
        }
        {
          type = "openai-compatible";
          name = "openrouter";
          api_base = "https://openrouter.ai/api/v1";
        }
        {
          type = "openai";
          api_base = "https://api.openai.com/v1";
        }
        {
          type = "openai-compatible";
          name = "mistral";
          api_base = "https://api.mistral.ai/v1";
        }
      ];
    };
  };
  programs.aider-chat = {
    enable = true;
    settings = {
      model = "deepseek/deepseek-chat";
      git = true;
      auto-commits = true;
      dark-mode = true;
    };
  };

  programs.zsh = {
    enable = true;
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

  programs.nh = {
    enable = true;
    #package = inputs.nh.packages.${pkgs.stdenv.hostPlatform.system}.default;
    clean = {
      enable = true;
      extraArgs = "--keep 5";
    };
  };

  programs.lazyvim = {
    enable = true;
    installCoreDependencies = false;
    
    extras = {
      ai."copilot-native".enable = true;
      lang.nix = {
        enable = true;
        installDependencies = false;
      };

      lang.rust = {
        enable = true;
        installDependencies = false; # keep sourcing rust-analyzer/codelldb from your devshell
        installRuntimeDependencies = false; # keep sourcing cargo/rustc from your devshell
      };

      dap.core = {
        enable = true;
        installDependencies = false; # keep sourcing codelldb from your devshell, same pattern as rust
      };

      lang.json = {
        enable = true;
        installDependencies = false;
      };
      lang.markdown = {
        enable = true;
        installDependencies = false;
      };

    };

    # Additional packages (optional)
    extraPackages = with pkgs; [
      nixd # Nix LSP
      alejandra # Nix formatter
      lua-language-server
      stylua
      marksman
      vscode-langservers-extracted
      prettier

      # Tools LazyVim/plugins expect on PATH
      ripgrep
      lazygit
      git
      gcc
      mermaid-cli
      wget
      curl
    ];

    # Only needed for languages not covered by LazyVim extras
    treesitterParsers = with pkgs.vimPlugins.nvim-treesitter-parsers; [
      wgsl # WebGPU Shading Language
      templ # Go templ files
      go
    ];

    config = {
      autocmds = ''
        vim.api.nvim_create_autocmd({ "InsertEnter" }, { command = "set norelativenumber" })
        vim.api.nvim_create_autocmd({ "InsertLeave" }, { command = "set relativenumber" })

        vim.api.nvim_create_autocmd("FileType", {
          pattern = "nix",
          callback = function(args)
            vim.lsp.inlay_hint.enable(false, { bufnr = args.buf })
          end,
        })
      '';
    };

    plugins = {
      disable-luarocks = ''
        return {
          {
            "folke/lazy.nvim",
            opts = {
              rocks = {
                enabled = false,
                hererocks = false,
              },
            },
          },
        }
      '';

      treesitter-no-autoinstall = ''
        return {
          {
            "nvim-treesitter/nvim-treesitter",
            opts = {
              auto_install = false,
              ensure_installed = {}, -- rely entirely on Nix-provided parsers
            },
          },
        }
      '';

      lspconfig = ''
        return {
          {
            "neovim/nvim-lspconfig",
            opts = {
              servers = {
                rust_analyzer = { enabled = false }, -- rustaceanvim handles this
                nixd = {},
              },
            },
          },
        }
      '';

      rust-dap = ''
        return {
          {
            "mrcjkb/rustaceanvim",
            opts = function(_, opts)
              local codelldb_symlink = vim.fn.exepath("codelldb")
              if codelldb_symlink ~= "" then
                local codelldb_real = vim.uv.fs_realpath(codelldb_symlink) or codelldb_symlink
                local liblldb_path = codelldb_real:gsub("adapter/codelldb$", "lldb/lib/liblldb.so")
                local cfg = require("rustaceanvim.config")
                opts.dap = opts.dap or {}
                opts.dap.adapter = cfg.get_codelldb_adapter(codelldb_real, liblldb_path)
              else
                vim.notify("codelldb not found on PATH — Rust debugging disabled", vim.log.levels.WARN)
              end
              return opts
            end,
          },
        }
      '';
    };
  };

  # xdg.configFile."nvim" = {
  #   source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/config/nvim";
  # };

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

    kubectl
    adwaita-fonts
  ];

}
