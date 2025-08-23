{ config, pkgs, ... }:

{

  home.username = "sysAdmin";
  home.homeDirectory = "/home/sysAdmin";

  home.packages = with pkgs; [
    sops
    git
    tree
    unixtools.ping
  ];

  home.stateVersion = "24.11";
  programs.home-manager.enable = true;

}
