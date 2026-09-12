{
  description = "Declare a new table and user for postgresql";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    { ... }:
    {
      nixosModules.postgresql-db =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          opts = config.services.postgresql-db;
        in
        {
          options.services.postgresql-db = {
            enable = lib.mkEnableOption "Postgres make DBs";

            dataDir = lib.mkOption {
              type = lib.types.path;
              default = "/var/lib/postgresql";
              description = "Where to store database data";
            };

            port = lib.mkOption {
              type = lib.types.port;
              default = 5432;
              description = "port to host postgresql";
            };

            credentialsFile = lib.mkOption {
              type = lib.types.path;
              description = ''
                File containing postgresql user credentials.
                Only the Passwords. Names of Users just follow the pattern:
                <DB_Name>_produser

                Password Format:
                PSQL_<DB>_PASSWORD=password
              '';
            };

            databases = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = ''
                List of databases to bootstrap.
                Each Database will recieve it's own user.
                The user credentials must be in the correct format in the credentials file.
              '';
            };

            ipMasks = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = ''
                List of ipMasks that psql will accept connections from
              '';
            };
          };

          config = lib.mkIf opts.enable {
            users.groups.postgres = { };
            users.users.postgres = {
              isSystemUser = true;
              createHome = true;
              home = opts.dataDir;
              group = "postgres";
            };

            services.postgresql = {
              enable = true;
              enableTCPIP = true;
              dataDir = opts.dataDir;
              settings.port = opts.port;
              settings.password_encryption = "scram-sha-256";
              identMap = ''
                postgres roy postgres
              '';

              authentication = pkgs.lib.mkOverride 10 ''
                local all postgres peer map=postgres
                local all all peer

                # Prod can be connected via local machine and declared masks
                ${lib.concatStringsSep "" (
                  map (db: "host ${db} ${db}_user 127.0.0.1/32 scram-sha-256\n") opts.databases
                )}
                ${lib.concatStringsSep "" (
                  map (db: "host ${db} ${db}_user ::1/128 scram-sha-256\n") opts.databases
                )}
                # configurable list of subnets allowed to connect (for example k3s pods subnet)
                # will allow connection to all declared ips. fine for now
                ${lib.concatStringsSep "" (
                  map (
                    db:
                    lib.concatStringsSep "" (map (mask: "host ${db} ${db}_user ${mask} scram-sha-256\n") opts.ipMasks)
                  ) opts.databases
                )}
              '';
            };

            systemd.services.bootstrap-psql = {
              description = "Bootstrap psql databases and users";
              after = [ "postgresql.service" ];
              requires = [ "postgresql.service" ];
              wantedBy = [ "multi-user.target" ];

              serviceConfig = {
                Type = "oneshot";
                User = "postgres";
                Group = "postgres";
                EnvironmentFile = opts.credentialsFile;

                ExecStart = pkgs.writeShellScript "bootstrap-psql" ''
                  set -euo pipefail

                  psql_bin=${pkgs.postgresql}/bin/psql

                  for db in ${lib.escapeShellArgs opts.databases}; do
                    db_upper="''${db^^}"

                    pass_var="PSQL_''${db_upper}_PASSWORD"

                    user_val="$db"_user
                    pass_val=$(eval "echo \''${$pass_var:-}")

                    if [ -z "$pass_val" ]; then
                      echo "Missing password credentials for database '$db'" >&2
                      exit 1
                    fi

                    echo "Bootstrapping PostgreSQL for database: $db"

                    # Create users if not exists
                    if $psql_bin --port=${toString opts.port} -c "\du" | grep -ci "$user_val"; then
                      echo "$user_val already exists, skipping creation. WARN: password may not be correct. Delete user and allow to be recreated for assurity"
                    else
                      echo "Creating $user_val"
                      $psql_bin --port=${toString opts.port} -c "CREATE ROLE "$user_val" WITH LOGIN PASSWORD '$pass_val';"
                    fi

                    # Create databases if not exists
                    if $psql_bin --port=${toString opts.port} -c "\l" | grep -ci ""$db" "; then
                      echo "$db already exists, skipping creation."
                    else
                      echo "Creating database $db"
                      $psql_bin --port=${toString opts.port} -c "CREATE DATABASE "$db" WITH OWNER "$user_val";"
                    fi

                    # Grant ownership (idempotency for weird states)
                    $psql_bin --port=${toString opts.port} -c "ALTER DATABASE "$db" OWNER TO "$user_val";"

                  done
                '';
              };
            };

            networking.firewall.allowedTCPPorts = lib.mkIf opts.enable [ opts.port ];
          };
        };
    };
}
