{ ... }: {
  # Configure nixvim
  programs.nixvim = {
    enable = true;
    globals.mapleader = " ";

    opts = {
      number = true;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
    };

    clipboard.register = "unnamedplus";

    keymaps = [
      {
        action = "<cmd>Neotree toggle<CR>";
        key = "<leader>b";
        mode = [ "n" ];
        options.silent = true;
        options.desc = "Toggle Neotree";
      }
      {
        action = "<C-w>h";
        key = "<leader>h";
        mode = [ "n" ];
        options.silent = true;
        options.desc = "Focus left";
      }
      {
        action = "<C-w>l";
        key = "<leader>l";
        mode = [ "n" ];
        options.silent = true;
        options.desc = "Focus right";
      }
      {
        action = "<C-w>j";
        key = "<leader>j";
        mode = [ "n" ];
        options.silent = true;
        options.desc = "Focus down";
      }
      {
        action = "<C-w>k";
        key = "<leader>k";
        mode = [ "n" ];
        options.silent = true;
        options.desc = "Focus up";
      }
    ];

    plugins = {
      lualine.enable = true;
      lsp-lines.enable = true;
      lsp-format.enable = true;

      lsp = {
        enable = true;
        inlayHints = true;

        servers = {
          html.enable = true;
          lua_ls.enable = true;
          nil_ls.enable = true;
          ts_ls.enable = true;
          marksman.enable = true;
          pyright.enable = true;
          gopls.enable = true;
          terraformls.enable = true;
          jsonls.enable = true;
          yamlls.enable = true;

          rust_analyzer = {
            enable = true;
            installRustc = true;
            installCargo = true;
            settings = {
              cargo = {
                features = "all";
              };
            };
          };
        };

        keymaps = {
          silent = true;

          lspBuf = {
            gd = {
              action = "definition";
              desc = "Goto Definition";
            };

            gr = {
              action = "references";
              desc = "Goto References";
            };

            gD = {
              action = "declaration";
              desc = "Goto Declaration";
            };

            gI = {
              action = "implementation";
              desc = "Goto Implementation";
            };

            gT = {
              action = "type_definition";
              desc = "Type Definition";
            };

            K = {
              action = "hover";
              desc = "Hover";
            };

            "<leader>cw" = {
              action = "workspace_symbol";
              desc = "Workspace Symbol";
            };

            "<leader>r" = {
              action = "rename";
              desc = "Rename";
            };
          };

          diagnostic = {
            "<leader>cd" = {
              action = "open_float";
              desc = "Line Diagnostics";
            };

            "]d" = {
              action = "goto_next";
              desc = "Next Diagnostic";
            };

            "[d" = {
              action = "goto_prev";
              desc = "Previous Diagnostic";
            };
          };
        };
      };

      neo-tree = {
        enable = true;
      };

      # neo-tree dependency
      web-devicons.enable = true;

      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          sources = [
            { name = "nvim_lsp"; }
            { name = "path"; }
            { name = "buffer"; }
            { name = "luasnip"; }
          ];
          mapping = {
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-d>" = "cmp.mapping.scroll_docs(-4)";
            "<C-e>" = "cmp.mapping.close()";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
          };
        };
      };
    };
    extraConfigLua = ''
      local _border = "rounded"

      vim.lsp.config('*', {
        handlers = {
          ["textDocument/hover"] = {
            border = _border,
          },
          ["textDocument/signatureHelp"] = {
            border = _border,
          },
        },
      })

      vim.diagnostic.config({
        float = {
          border = _border,
        },
      })
    '';

    colorschemes.catppuccin = {
      enable = true;
      settings.flavour = "frappe";
    };
  };
}
