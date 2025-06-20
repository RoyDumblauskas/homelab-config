{
  description = "minio service for storing images with api access";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosModules.minio-service = { config, lib, pkgs, ... }:
      let
        opts = config.services.minio-service;
      in {
        options.services.minio-service = {
          enable = lib.mkEnableOption "MinIO object storage server";

          dataDir = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/minio";
            description = "Directory to store MinIO data.";
          };

          dataPort = lib.mkOption {
            type = lib.types.port;
            default = 9000;
            description = "MinIO S3 API port.";
          };

          consolePort = lib.mkOption {
            type = lib.types.port;
            default = 9001;
            description = "MinIO Admin Console port.";
          };

          credentialsFile = lib.mkOption {
            type = lib.types.path;
            description = "File containing MinIO credentials.";
          };

          default-nginx = {
            enable = lib.mkEnableOption "Enable nginx reverse proxy for MinIO";
            hostname = lib.mkOption {
              type = lib.types.str;
              default = "localhost";
              description = "Hostname for nginx reverse proxy.";
            };
          };
        };

        config = lib.mkIf opts.enable {
          users.groups.minio = {};
          users.users.minio = {
            isSystemUser = true;
            createHome = true;
            home = "${opts.dataDir}";
            group = "minio";
          };

          systemd.services.minio = {
            description = "MinIO S3-compatible object storage";
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];

            serviceConfig = {
              ExecStart = ''
                ${pkgs.minio}/bin/minio server ${opts.dataDir} \
                  --address ":${toString opts.dataPort}" \
                  --console-address ":${toString opts.consolePort}"
              '';

              User = "minio";
              Group = "minio";
              EnvironmentFile = "${opts.credentialsFile}"; 
              Restart = "always";
            };
          };

          services.nginx = lib.mkIf opts.default-nginx.enable {
            enable = true;
            virtualHosts.${opts.default-nginx.hostname} = {
              forceSSL = true;
              enableACME = true;
              acmeRoot = null;
              locations."/" = {
                proxyPass = "http://localhost:${toString opts.dataPort}";
              };
              locations."/console/" = {
                proxyPass = "http://localhost:${toString opts.consolePort}";
              };
            };
          };

          networking.firewall.allowedTCPPorts = lib.mkMerge [
            (lib.mkIf opts.enable [ opts.dataPort opts.consolePort ])
            (lib.mkIf opts.default-nginx.enable [ 80 443 ])
          ];
        };
      };
  };
}
