{ config, pkgs, sops, ... }:

{

  home.username = "sysAdmin";
  home.homeDirectory = "/home/sysAdmin";

  # Secret Management
  sops = {
    age.keyFile = "./age/keys.txt"; # Make sure to gitignore, contains private key.

    defaultSopsFile = ./secrets/build.json;
    defaultSymlinkPath = "/run/user/1000/secrets";
    defaultSecretsMountPoint = "/run/user/1000/secrets.d";

    secrets.homelabBuild = {
      path = "${config.sops.defaultSymlinkPath}/homelabBuild";
    };
  };

  home.packages = with pkgs; [
    git
    tree
  ];

  home.stateVersion = "24.11";
  programs.home-manager.enable = true;

}
