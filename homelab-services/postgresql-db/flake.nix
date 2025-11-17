{
  description = "Declare a new table and user for postgresql";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ...}: {
    nixosModules.postgresql-db = {config, lib, pkgs, ...}:
    let
      opts = config.services.postgresql-db;
    in {
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
            description = "File containing postgresql user credentials";
        };

        databases = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "list of databases to bootstrap";
        };
      };

      config = lib.mkIf opts.enable {
        users.groups.postgres = {};
        users.users.postgres = {
          isSystemUser = true;
          createHome = true;
          home = opts.dataDir;
          group = "postgres";
        };

        services.postgresql = {
          enable = true;
          dataDir = opts.dataDir;
          settings.port = opts.port;
          identMap = ''
            postgres roy postgres
            two roy freakonomics
          '';
        };

        systemd.services.bootstrap-psql = {
          description = "Bootstrap psql dbs and users";
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

                user_var="PSQL_''${db_upper}_USER"
                pass_var="PSQL_''${db_upper}_PASSWORD"

                user_val=$(eval "echo \''${$user_var:-}")
                pass_val=$(eval "echo \''${$pass_var:-}")

                if [ -z "$user_val" ] || [ -z "$pass_val" ]; then
                  echo "Missing credentials for database '$db' ($user_var / $pass_var)" >&2
                  exit 1
                fi

                echo "Bootstrapping PostgreSQL for database: $db"

                # CREATE USER (if not exists)
                $psql_bin --tuples-only --no-align -c \
                  "SELECT 1 FROM pg_roles WHERE rolname='\$${user_val}'" | grep -q 1 \
                  || $psql_bin -c "CREATE USER ''${user_val} WITH PASSWORD '\$${pass_val}';"

                # CREATE DATABASE (if not exists)
                $psql_bin --tuples-only --no-align -c \
                  "SELECT 1 FROM pg_database WHERE datname='\$${db}'" | grep -q 1 \
                  || $psql_bin -c "CREATE DATABASE ''${db} OWNER '\$${user_val}';"

                # Privileges
                $psql_bin -c "ALTER DATABASE ''${db} OWNER TO ''${user_val};"
                $psql_bin -d "$db" -c "GRANT ALL PRIVILEGES ON DATABASE ''${db} TO ''${user_val};"

                echo "Bootstrapped DB ''${db} (user: ''${user_val})"
              done
            '';
            };
          };
      };
    };
  };
}
