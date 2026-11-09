# LazyVim (Neovim) via lazyvim-nix: LSPs/formatters from Nix, no Mason/luarocks/treesitter
# auto-install. Language toolchains (cargo, rust-analyzer, codelldb) come from the project
# devshell, so the Rust/DAP extras don't install them here.
{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.nixConfig.lazyvim.enable = lib.mkEnableOption "LazyVim (Neovim) with Nix-provided tooling";

  config = lib.mkIf config.nixConfig.lazyvim.enable {
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
        nixd
        alejandra
        lua-language-server
        stylua
        marksman
        vscode-langservers-extracted
        prettier
        copilot-language-server

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
        options = ''
          -- the vscode import lives in lua/plugins/, so LazyVim's import-order check would warn inside VS Code
          if vim.g.vscode then vim.g.lazyvim_check_order = false end
          -- lazyvim-nix's starter hardcodes "tutor" in performance.rtp.disabled_plugins (no option to change it);
          -- source the stock plugin to restore :Tutor
          vim.cmd.runtime("plugin/tutor.vim")
        '';
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
        vscode = ''
          return {
            { import = "lazyvim.plugins.extras.vscode", cond = vim.g.vscode ~= nil },
          }
        '';
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

        dap-ui-autoclose = ''
          return {
            {
              "rcarriga/nvim-dap-ui",
              opts = function(_, opts)
                local dap = require("dap")

                local function reset_explorer_width()
                  vim.defer_fn(function()
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                      local buf = vim.api.nvim_win_get_buf(win)
                      if vim.bo[buf].filetype == "snacks_picker_list" then
                        vim.api.nvim_win_set_width(win, 30)
                      end
                    end
                  end, 100)
                end

                local function on_end()
                  require("dapui").close()
                  reset_explorer_width()
                end

                dap.listeners.before.event_terminated["close_dapui"] = on_end
                dap.listeners.before.event_exited["close_dapui"] = on_end
                return opts
              end,
            },
          }
        '';
      };
    };
  };
}
