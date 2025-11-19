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
            description = ''
              File containing postgresql user credentials.
              Format:

              PSQL_DB_USER=username
              PSQL_DB_PASSWORD=password
              PSQL_DB_DEV_USER=dev_username
              PSQL_DB_DEV_PASSWORD=dev_password
            '';
        };

        databases = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "list of databases to bootstrap. Will expand into DB, and DB-DEV for each item. And each Database will recieve it's own user. The user credentials must be in the correct format in the credentials file.";
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
          '';

          # allow remote connections to dev DBs
          authentication = ''
            ${lib.concatStringsSep "" (map (db: "host ${db}_dev all samenet md5\n") opts.databases) }  
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
                dev_user_var="PSQL_''${db_upper}_DEV_USER"
                dev_pass_var="PSQL_''${db_upper}_DEV_PASSWORD"

                user_val=$(eval "echo \''${$user_var:-}")
                pass_val=$(eval "echo \''${$pass_var:-}")
                dev_user_val=$(eval "echo \''${$dev_user_var:-}")
                dev_pass_val=$(eval "echo \''${$dev_pass_var:-}")

                if [ -z "$user_val" ] || [ -z "$pass_val" ]; then
                  echo "Missing credentials for database '$db' ($user_var / $pass_var)" >&2
                  exit 1
                fi

                if [ -z "$dev_user_val" ] || [ -z "$dev_pass_val" ]; then
                  echo "Missing credentials for database '$db'_dev ($dev_user_var / $dev_pass_var)" >&2
                  exit 1
                fi

                echo "Bootstrapping PostgreSQL for database: $db"
                echo $user_val
                echo $pass_val
                echo $dev_user_val
                echo $dev_pass_val

                # Create databases
                $psql_bin -c "CREATE DATABASE "$db";"
                $psql_bin -c "CREATE DATABASE "$db"_dev;"

                # Create users if not exists
                $psql_bin -c "CREATE ROLE "$user_val" WITH LOGIN PASSWORD "$pass_val";"
                $psql_bin -c "CREATE ROLE "$dev_user_val" WITH LOGIN PASSWORD "$dev_pass_val";"

                # Give users privileges on databases
                $psql_bin -c "GRANT ALL PRIVELEGES ON DATABASE "$db" TO "$user_val";"
                $psql_bin -c "GRANT ALL PRIVELEGES ON DATABASE "$db"_dev TO "$dev_user_val";"

              done
            '';
            };
          };
      };
    };
  };
}
