{ pkgs, inputs, ... }:

{

  home.username = "roy";
  home.homeDirectory = "/home/roy";

  home.packages = with pkgs; [
    age
    awscli2
    dig
    discord
    ffmpeg_6
    fish
    git
    git-filter-repo
    grim
    kdePackages.gwenview
    minio-client
    prismlauncher
    slurp
    sops
    ssh-to-age
    tree
    tmux
    unzip
    vlc
    wl-clipboard
    yq-go
    zip
  ];

  programs.git = {
    enable = true;
    userName = "Roy Dumblauskas";
    userEmail = "roydumblauskas@gmail.com";
  };

  # user program config files
  home.file = {
    ".config/hypr".source = ./roy-config/hypr;
    ".config/waybar".source = ./roy-config/waybar;
    ".config/fish".source = ./roy-config/fish;
    ".config/alacritty".source = ./roy-config/alacritty;
  };
  
  # user persisted dirs
  home.persistence."/persist/home/roy" = {
    directories = [
      ".ssh"
      "rp"
      "dl"
      ".mozilla/firefox/roy/storage/default"
      ".cache/mozilla/firefox/roy"
    ];
    files = [
      ".bash_history"
      ".mozilla/firefox/roy/places.sqlite"
      ".mozilla/firefox/roy/cookies.sqlite"
      ".config/sops/age/keys.txt"

    ];
    allowOther = true;
  };

  # User services must come after sops secrets
  systemd.user.services.mbsync.unitConfig.After = [ "sops-nix.service" ];

  # Configure firefox to be resilient against reboot
  # Source = https://github.com/johnmpost/nixos-config
  programs.firefox = {
    enable = true;

    profiles.roy = {
      search = {
        force = true;
        default = "ddgc";
        privateDefault = "ddgc";
        engines = {
          bing.metaData.hidden = true;
          ddg.metaData.hidden = true;
          google.metaData.hidden = true;
          wikipedia.metaData.hidden = true;
          amazon.metaData.hidden = true;
          ebay.metaData.hidden = true;
          ddgc = {
            name = "DuckDuckGo (unthemed)";
            urls = [{ template = "https://duckduckgo.com/?q={searchTerms}"; }];
            icon = "https://duckduckgo.com/favicon.ico";
          };
        };
      };

      extensions.force = true;
      extensions.packages = with inputs.firefox-addons.packages.${pkgs.system}; [
	      ublock-origin
        vimium-c
	    ];
      extensions.settings."uBlock0@raymondhill.net".settings = {
        selectedFilterLists = [
          "ublock-filters"
          "ublock-badware"
          "ublock-privacy"
          "ublock-quick-fixes"
          "ublock-unbreak"
          "easylist-chat"
          "easylist-newsletters"
          "easylist-notifications"
          "easylist-annoyances"
          "adguard-mobile-app-banners"
          "adguard-other-annoyances"
          "adguard-popup-overlays"
          "adguard-widgets"
          "ublock-annoyances"
        ];
      };

      settings = {
        # don't force manual enablement of extensions on first launch
        "extensions.autoDisableScopes" = 0;
        "browser.urlbar.shortcuts.bookmarks" = false;
        "browser.urlbar.shortcuts.history" = false;
        "browser.urlbar.shortcuts.tabs" = false;
        "browser.aboutConfig.showWarning" = false;
        "dom.security.https_only_mode" = true;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.pbmode.enabled" = true;
        "privacy.donottrackheader.enabled" = true;
        "signon.rememberSignons" = false;
        "extensions.formautofill.creditCards.enabled" = false;
        "extensions.formautofill.addresses.enabled" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        # hide weather on new tab page
        "browser.newtabpage.activity-stream.showWeather" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.toolbars.bookmarks.visibility" = "never";
        # set default download dir (to avoid Download dir creation)
        "browser.download.dir" = "/home/roy/dl";
        "browser.download.useDownloadDir" = false;
        "browser.download.folderList" = 2;
        "full-screen-api.ignore-widgets" = true;
        "browser.tabs.firefox-view" = false;
        "browser.gesture.swipe.left" = "";
        "browser.gesture.swipe.right" = "";
        "pdfjs.sidebarViewOnLoad" = 0;
        "identity.fxaccounts.enabled" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.uitour.enabled" = false;
        "toolkit.telemetry.enabled" = false;
        # don't show about:welcome or privacy page on first launch
        "browser.aboutwelcome.enabled" = false;
        "datareporting.policy.dataSubmissionPolicyBypassNotification" = true;
        # disable pocket
        "extensions.pocket.enabled" = false;
        # keep window open when closing all tabs
        "browser.tabs.closeWindowWithLastTab" = false;
        # allegedly disable addon recommendations
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
        # allegedly disable feature recommendations
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
        # don't show "open previous tabs?" toolbar, hopefully still allow functionality
        "browser.startup.couldRestoreSession.count" = -1;
      };

      bookmarks.force = true;
      bookmarks.settings = [
        {
          name = "google search";
          url = "https://www.google.com/search?q=%s";
          keyword = "g";
        }
        {
          name = "youtube search";
          url = "https://www.youtube.com/results?search_query=%s";
          keyword = "yt";
        }
        {
          name = "wikipedia search";
          url = "https://en.wikipedia.org/wiki/Special:Search?search=%s";
          keyword = "w";
        }
        {
          name = "dictionary search";
          url = "https://www.wordnik.com/words/%s";
          keyword = "d";
        }
        {
          name = "github go to repo";
          url = "https://github.com/RoyDumblauskas/%s";
          keyword = "repo";
        }
        {
          name = "chatgpt";
          url = "https://chatgpt.com";
          keyword = "chat";
        }
        {
          name = "github my repos";
          url = "https://github.com/RoyDumblauskas?tab=repositories";
          keyword = "repos";
        }
        {
          name = "github profile";
          url = "https://github.com/RoyDumblauskas";
          keyword = "gh";
        }
        {
          name = "drive 0";
          url = "https://drive.google.com/drive/u/0/folders/1hMAgupSZvhAml0K1WhBi9sNINfvkhw0e";
          keyword = "d0";
        }
        {
          name = "drive 1";
          url = "https://drive.google.com/drive/u/1";
          keyword = "d1";
        }
        {
          name = "mail 1";
          url = "https://mail.google.com/mail/u/1";
          keyword = "m1";
        }
        {
          name = "mail 0";
          url = "https://mail.google.com/mail/u/0";
          keyword = "m0";
        }
        {
          name = "discord";
          url = "https://discord.com/app";
          keyword = "dis";
        }
        {
          name = "downloads";
          url = "file:///home/roy/dl/%s";
          keyword = "dl";
        }
        {
          name = "nix package search";
          url = "https://search.nixos.org/packages?channel=unstable&query=%s";
          keyword = "nixp";
        }
      ];
    };
  };

  # Configure nixvim
  programs.nixvim = {
    enable = true;
    globals.mapleader = " ";
    opts = {
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
    };

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

      neo-tree = {
        enable = true;
      };

      # neo-tree dependency
      web-devicons.enable = true;

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
	        ansiblels.enable = true;
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

      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          sources = [
            {name = "nvim_lsp";}
            {name = "path";}
            {name = "buffer";}
            {name = "luasnip";}
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

      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
        vim.lsp.handlers.hover, {
          border = _border
        }
      )

      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
        vim.lsp.handlers.signature_help, {
	        border = _border
	      }
      )

      vim.diagnostic.config{
      	float={border=_border}
      };

      require('lspconfig.ui.windows').default_options = {
        border = _border
      }
    '';

    colorschemes.catppuccin = {
      enable = true;
      settings.flavour = "frappe";
    };
  };


  home.stateVersion = "24.11";
  programs.home-manager.enable = true;

}
