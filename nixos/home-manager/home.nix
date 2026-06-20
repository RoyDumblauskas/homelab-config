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
  };

  # user persisted dirs
  home.persistence."/persist" = {
    directories = [
      ".ssh"
      "rp"
      "dl"
    ];
    files = [
      ".bash_history"
      ".config/sops/age/keys.txt"
    ];
  };

  # User services must come after sops secrets
  systemd.user.services.mbsync.unitConfig.After = [ "sops-nix.service" ];

  home.stateVersion = "24.11";
  programs.home-manager.enable = true;

}
