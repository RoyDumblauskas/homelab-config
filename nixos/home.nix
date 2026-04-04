{ config, pkgs, ... }:

{

  home.username = "sysAdmin";
  home.homeDirectory = "/home/sysAdmin";

  home.packages = with pkgs; [
    sops
    ssh-to-age
    git
    tree
    unixtools.ping
  ];

  # user persisted dirs
  home.persistence."/persist" = {
    directories = [
      ".ssh"
      "rp"
    ];
    files = [
      ".bash_history"
      ".config/sops/age/keys.txt"

    ];
  };

  home.stateVersion = "24.11";
  programs.home-manager.enable = true;

}
