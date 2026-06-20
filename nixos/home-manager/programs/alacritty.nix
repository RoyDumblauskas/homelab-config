{ ... }: {
  programs.alacritty = {
    enable = true;
    theme = "catppuccin_frappe";

    settings = {
      terminal.shell = "fish";

      font = {
        normal.family = "UbuntuMono Nerd Font";
        italic.family = "UbuntuMono Nerd Font";
        bold.family = "UbuntuMono Nerd Font";
        size = 16;
      };

      window = {
        decorations = "full";
        opacity = 1;
      };
    };

  };
}
