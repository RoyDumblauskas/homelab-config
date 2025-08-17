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
              Environment = ''
                MINIO_BROWSER_REDIRECT_URL=https://${opts.default-nginx.hostname}/console
              '';
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

                alias_name="local"
                mc_bin=${pkgs.minio-client}/bin/mc

                # Delete alias if it already exists
                mc alias rm local || true

                # Point mc at the local minio instance
                $mc_bin alias set "$alias_name" http://localhost:${toString opts.dataPort} \
                  "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"

                # Loop through requested environments
                for env in ${lib.escapeShellArgs opts.bootstrap-minio.environments}; do
                  bucket="$env"
                  user_var="MINIO_''${env^^}_USER"
                  pass_var="MINIO_''${env^^}_PASSWORD"

                  # expand env var names dynamically
                  user_val=$(eval "echo \''${$user_var:-}")
                  pass_val=$(eval "echo \''${$pass_var:-}")

                  if [ -z "$user_val" ] || [ -z "$pass_val" ]; then
                    echo "Missing credentials for $env ($user_var / $pass_var)" >&2
                    exit 1
                  fi

                  policy="policy-$env"

                  echo "Bootstrapping environment: $env"

                  # Create bucket if not exists
                  $mc_bin mb --ignore-existing "$alias_name/$bucket"

                  # Set bucket limit in future
                  # $mc_bin bucket quota is deprecated

                  # Create policy JSON (full access to that bucket)
                  policy_file=$(mktemp)
                  cat > "$policy_file" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": [
        "arn:aws:s3:::$bucket",
        "arn:aws:s3:::$bucket/*"
      ]
    }
  ]
}
EOF

                  # Apply policy
                  $mc_bin admin policy create "$alias_name" "$policy" "$policy_file"

                  # Create or update user
                  if ! $mc_bin admin user info "$alias_name" "$user_val" >/dev/null 2>&1; then
                    $mc_bin admin user add "$alias_name" "$user_val" "$pass_val"
                    echo "Created user $user_val"
                  fi

                  # Attach policy
                  $mc_bin admin policy attach "$alias_name" "$policy" --user "''${user_val}"

                  rm -f "$policy_file"
                done
              '';
              User = "minio";
              Group = "minio";
              EnvironmentFile = "${opts.credentialsFile}";
              
            };
          };

          services.nginx = lib.mkIf opts.default-nginx.enable {
            enable = true;
            virtualHosts.${opts.default-nginx.hostname} = {
              forceSSL = true;
              enableACME = true;
              acmeRoot = null;

              locations."/console" = {
                proxyPass = "http://localhost:${toString opts.consolePort}";
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

