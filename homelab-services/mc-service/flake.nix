{

  description = "Declarative MC config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
  };

  outputs = { nixpkgs, nix-minecraft, ... }: {
    nixosModules.mc-service =
      {
        config,
        lib,
        ...
      }:
      let
        system = "x86_64-linux";
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ nix-minecraft.overlay ];
          config = {
            allowUnfree = true;
          };
        };
        opts = config.services.mc-service;
      in
      {

        imports = [ nix-minecraft.nixosModules.minecraft-servers ];

        options.services.mc-service = {
          enable = lib.mkEnableOption "Enable Minecraft Server";

          storeDir = lib.mkOption {
            type = lib.types.path;
            default = "/persist/srv/minecraft";
            description = "Minecraft files locations";

          };

          rconSecrets = lib.mkOption {
            type = lib.types.path;
            description = "minecraft rcon secret";
          };
        };

        config = lib.mkIf opts.enable {
          users.groups.mc-service = { };
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
                enable-rcon = true;
                "rcon.password" = "CHANGE_THIS_SECRET";
              };

              package = pkgs.fabricServers.fabric-26_2.override {
                jre_headless = pkgs.openjdk25_headless;
              };

              symlinks = {
                mods = pkgs.linkFarmFromDrvs "mods" (
                  builtins.attrValues {
                    Sleep = pkgs.fetchurl {
                      url = "https://cdn.modrinth.com/data/WTzuSu8P/versions/epDz3qzS/sleep-v4.3.18.jar";
                      sha512 = "f4bfd7bf8c9dc64640a3f1353993341cccb9d76f5b0aed8f746ed7159689a336b2ddc1bcc3ec2ea5cb70d0ecee9072a325c33d4a56179a22e98d4c2849bc6971";
                    };
                    Lithium = pkgs.fetchurl {
                      url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/UPNexAfy/lithium-fabric-0.25.2%2Bmc26.2.jar";
                      sha512 = "db676376c05b7e912cdae5aad9e51f125adc1554ae2b204599ccb598751921aedbac98e97b9cba0333b6b52488c6b75c915a7dbd50436f97800387fe1aad1c50";
                    };
                    FabricAPI = pkgs.fetchurl {
                      url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/lVXlbH4w/fabric-api-0.155.2%2B26.2.jar";
                      sha512 = "cc56984378a27c5bcd56374d6ffbb27a45c6bf3355add2ac6be9817ccac5854362249bf9d0147eb271a70fda2716129204e240d53c9aa876a2a7861f4c7f880f";
                    };
                    Chunky = pkgs.fetchurl {
                      url = "https://cdn.modrinth.com/data/fALzjamp/versions/4Eotm6ov/Chunky-Fabric-1.5.3.jar";
                      sha512 = "b83bfe7b218d0aa6232af977ae741dc1f82b10e50cd12bb759f65cf416b8b62beccb543e587ef0b9670abe03815660f8e091bc6823624d65cf07300571573516";
                    };
                  }
                );
              };
            };
          };
        };
      };
  };
}
