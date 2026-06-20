{
  config,
  inputs,
  pkgs,
  ...
}:
{
  # Configure firefox to be resilient against reboot
  # Source = https://github.com/johnmpost/nixos-config
  programs.firefox = {
    enable = true;

    configPath = "${config.xdg.configHome}/mozilla/firefox";

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
            urls = [ { template = "https://duckduckgo.com/?q={searchTerms}"; } ];
            icon = "https://duckduckgo.com/favicon.ico";
          };
        };
      };

      extensions.force = true;
      extensions.packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
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
}
