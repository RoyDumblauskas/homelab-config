{

  description = "Declarative MC config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
  };

  outputs = { self, nixpkgs, nix-minecraft }@inputs: {

    nixosModules.mc-service = { config, lib, pkgs, ... }:
    let 
      system = "x86_64-linux"; # change this to your system string
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nix-minecraft.overlay ];
        config = { };
      };
      opts = config.services.mc-service;
    in {

      imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];

      options.services.mc-service = {
        enable = lib.mkEnableOption "Enable Minecraft Server";

        storeDir = lib.mkOption {
          type = lib.types.path;
          default = "/persist/srv/minecraft";
          description = "Minecraft files locations";
        
        };
      };

      config = lib.mkIf opts.enable {
        users.groups.mc-service = {};
        users.users.mc-service = {
          isSystemUser = true;
          createHome = true;
          home = "${opts.storeDir}";
          group = "mc-service";
        };
        
        services.minecraft-servers = {
          enable = true;
          eula = true;
          openFirewall = true;
          dataDir = "${opts.storeDir}";
          users = "mc-service";
          group = "mc-service";

          servers.homeServer = {
            enable = true;
            restart = "always";
            jvmOpts = "-Xmx16G -Xms8G";
            serverProperties = {
              server-port = 25565;
              difficulty = 3;
              gamemode = 0;
              force-gamemode = true;
              max-players = 10;
              motd = "Home MC Server";
              white-list = false;
            };

            # Specify the custom minecraft server package
            package = pkgs.fabricServers.fabric;
          };
        };
      };
    };
  };
}
