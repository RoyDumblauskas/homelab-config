{

  description = "Declarative MC config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-minecraft,
    }:
    {

      nixosModules.mc-service =
        {
          config,
          lib,
          pkgs,
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
                };

                package = pkgs.fabricServers.fabric-26_2.override {
                  jre_headless = pkgs.openjdk25_headless;
                };
              };
            };
          };
        };
    };
}
