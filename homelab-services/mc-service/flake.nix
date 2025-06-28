{

  description = "Declarative MC config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
  };

  outputs = { self, nixpkgs, nix-minecraft }: {

    nixosModules.mc-service = { config, lib, pkgs, ... }:
    let 
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nix-minecraft.overlay ];
        config = { allowUnfree = true; };
      };
      opts = config.services.mc-service;
    in {

      imports = [ nix-minecraft.nixosModules.minecraft-servers ];

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
          user = "mc-service";
          group = "mc-service";

          servers.homeServer = {
            enable = true;
            restart = "always";
            jvmOpts = "-Xmx16G -Xms16G";
            whitelist = {
              SquidMcJiggles = "7ae4f5a9-dc2b-4b42-ab30-f8d10d38fa83";
            };
            serverProperties = {
              server-port = 25565;
              difficulty = 3;
              gamemode = 0;
              force-gamemode = true;
              max-players = 10;
              motd = "Home MC Server";
              white-list = true;
              spawn-protection = 0;
            };

            package = pkgs.fabricServers.fabric;

            symlinks = {
              mods = pkgs.linkFarmFromDrvs "mods" (builtins.attrValues {
                Sleep = pkgs.fetchurl { 
                  url = "https://cdn.modrinth.com/data/WTzuSu8P/versions/w4ONshdx/sleep-v4.1.4.jar";
                  sha512 = "f4f759a6b9f503ed606bbeb3422b5e31c02d99a7ee91befa7fc4afe364db147bd1e03042d4b6e67bebed7f81e34d6aa60a3a5d690011ef0e726190028d903346";
                };
                Lithium = pkgs.fetchurl {
                  url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/XWGBHYcB/lithium-fabric-0.17.0%2Bmc1.21.6.jar";
                  sha512 = "a8d6a8b69ae2b10dd0cf8f8149260d5bdbd2583147462bad03380014edd857852972b967d97df69728333d8836b1e9db8997712ea26365ddb8a05b8c845c6534";
                };
                FabricAPI = pkgs.fetchurl {
                  url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/b2dnY6PN/fabric-api-0.128.0%2B1.21.6.jar";
                  sha512 = "c668402e1a877c2d572d16e31e6d2783be27a80993fa83bf040ea2007994518786bd3140dcea15334f8ee1630836292b8ae4d41444e47cba0ac43d05f1eb1e78";
                };
              });
            };
          };

          servers.testingServer = {
            enable = true;
            restart = "always";
            jvmOpts = "-Xmx1G -Xms1G";
            whitelist = {
              SquidMcJiggles = "7ae4f5a9-dc2b-4b42-ab30-f8d10d38fa83";
            };
            serverProperties = {
              server-port = 43000;
              difficulty = 3;
              gamemode = 1;
              force-gamemode = true;
              max-players = 2;
              motd = "Mod Test Server";
              white-list = true;
              spawn-protection = 0;           
            };

            package = pkgs.fabricServers.fabric;

            symlinks = {
              mods = pkgs.linkFarmFromDrvs "mods" (builtins.attrValues {
                Sleep = pkgs.fetchurl { 
                  url = "https://cdn.modrinth.com/data/WTzuSu8P/versions/w4ONshdx/sleep-v4.1.4.jar";
                  sha512 = "f4f759a6b9f503ed606bbeb3422b5e31c02d99a7ee91befa7fc4afe364db147bd1e03042d4b6e67bebed7f81e34d6aa60a3a5d690011ef0e726190028d903346";
                };
                Lithium = pkgs.fetchurl {
                  url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/XWGBHYcB/lithium-fabric-0.17.0%2Bmc1.21.6.jar";
                  sha512 = "a8d6a8b69ae2b10dd0cf8f8149260d5bdbd2583147462bad03380014edd857852972b967d97df69728333d8836b1e9db8997712ea26365ddb8a05b8c845c6534";
                };
                FabricAPI = pkgs.fetchurl {
                  url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/b2dnY6PN/fabric-api-0.128.0%2B1.21.6.jar";
                  sha512 = "c668402e1a877c2d572d16e31e6d2783be27a80993fa83bf040ea2007994518786bd3140dcea15334f8ee1630836292b8ae4d41444e47cba0ac43d05f1eb1e78";
                };
              });
            };
          };
        };
      };
    };
  };
}
