{ config, pkgs, sops, ... }:

{

  home.username = "sysAdmin";
  home.homeDirectory = "/home/sysAdmin";

  # Secret Management
  sops = {
    age.keyFile = "/home/sysAdmin/.config/sops/age/keys.txt"; # No password!

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
