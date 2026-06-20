{ pkgs, ... }:

{

  # import longer service declarations
  imports = [
    ./programs
  ];

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
    go
    grim
    jq
    kdePackages.gwenview
    minio-client
    nodejs_22
    postman
    prismlauncher
    python3
    slurp
    sops
    spotify
    ssh-to-age
    tree
    tmux
    unzip
    vlc
    wl-clipboard
    woeusb
    wofi
    xrandr
    yq-go
    zip
  ];

  # user program config files
  home.file = {
    ".config/hypr".source = ../roy-config/hypr;
    ".config/waybar".source = ../roy-config/waybar;
    ".local/share/PrismLauncher/instances/1.21.6/minecraft/options.txt".source =
      ../roy-config/PrismLauncher/instances/1.21.6/minecraft/options.txt;
    ".local/share/PrismLauncher/instances/1.21.6/minecraft/servers.dat".source =
      ../roy-config/PrismLauncher/instances/1.21.6/minecraft/servers.dat;
  };

  # user persisted dirs
  home.persistence."/persist" = {
    directories = [
      ".ssh"
      "rp"
      "dl"
      # persist steam
      ".local/share/Steam"
      # persist spotify
      ".config/spotify"
      ".cache/spotify"
    ];
    files = [
      ".bash_history"
      ".config/sops/age/keys.txt"
      ".local/share/PrismLauncher/accounts.json"
      ".local/share/PrismLauncher/instances/1.21.6/instance.cfg"
      ".local/share/PrismLauncher/instances/1.21.6/mmc-pack.json"
    ];
  };

  # User services must come after sops secrets
  systemd.user.services.mbsync.unitConfig.After = [ "sops-nix.service" ];

  home.stateVersion = "24.11";
  programs.home-manager.enable = true;

}
