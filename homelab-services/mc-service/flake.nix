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
              Baloneyjohn = "aa33ea9c-05ce-46d4-9ae3-715c80f618da";
              Beankurd = "4bdd135f-e9a6-4830-9755-6282ec71e338";
              couchdomination = "6272ebe9-6191-43fa-adbd-9d1a9ca36a8c";
              Grutkoek = "bb1b7067-18d8-4d63-92fa-49b003d39826";
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
                ScaleableLux = pkgs.fetchurl {
                  url = "https://cdn.modrinth.com/data/Ps1zyz6x/versions/PQLHDg2Q/ScalableLux-0.1.5%2Bfabric.e4acdcb-all.jar";
                  sha512 = "ec8fabc3bf991fbcbe064c1e97ded3e70f145a87e436056241cbb1e14c57ea9f59ef312f24c205160ccbda43f693e05d652b7f19aa71f730caec3bb5f7f7820a"; 
                };
                Noisium = pkgs.fetchurl {
                  url = "https://cdn.modrinth.com/data/KuNKN7d2/versions/V9mMIy0f/noisium-fabric-2.7.0%2Bmc1.21.6.jar";
                  sha512 = "80cc286f3a51b2d12304ef6a44f84c11d67cedec1a02fbaf59e2e816d9b5f0abd17cc6b5a0ca5880935e9dadfea3b951b790ee1e54300c009bc419c1c7451785";
                };
                C2ME = pkgs.fetchurl {
                  url = "https://cdn.modrinth.com/data/VSNURh3q/versions/Erjpfj2l/c2me-fabric-mc1.21.7-0.3.4%2Bbeta.1.0.jar";
                  sha512 = "8942e82c216315198d4752fbb9396e6d59d6447085ce5c00811ba0189765b20acad0153a10532f7ade29f7c090e0299c01802174aa89d4da642bc10f9429998d";
                };
              });
            };
          };
        };
      };
    };
  };
}
