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

          bootstrap-minio = {
            enable = lib.mkEnableOption "Enable bootstrapping minio creds";
            environments = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "list of environments to bootstrap (dev, prod, stage, etc)";
            };
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

          systemd.services.bootstrap-minio = lib.mkIf opts.bootstrap-minio.enable {
            description = "Minio bootstrap users, policies, buckets";
            after = [ "minio.service" ];
            requires = [ "minio.service" ];
            wantedBy = [ "multi-user.target" ];

            serviceConfig = {
              Type = "oneshot";
              ExecStart = pkgs.writeShellScript "bootstrap-minio" ''
                set -euo pipefail

                echo $SHELL
              '';
              User = "minio";
              Group = "minio";
              
            };
          };

          services.nginx = lib.mkIf opts.default-nginx.enable {
            enable = true;
            virtualHosts.${opts.default-nginx.hostname} = {
              forceSSL = true;
              enableACME = true;
              acmeRoot = null;
              # Dev and Prod buckets must be created manually
              # will work on script/minio command line for this later
              locations."/console" = {
                proxyPass = "http://localhost:${toString opts.consolePort}/browser";
              };
              # Add directive for s3like queries, which only accept root path allegedly
              locations."/" = {
                proxyPass = "http://localhost:${toString opts.dataPort}";
                extraConfig = ''
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_set_header X-Forwarded-Proto $scheme;
                  client_max_body_size 0;
                  proxy_buffering off;
                '';
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

