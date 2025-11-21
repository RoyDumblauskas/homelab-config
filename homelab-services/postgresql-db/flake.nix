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
              Only the Passwords. Names of Users just follow the pattern:
              <DB_Name>_produser
              <DB_Name>_devuser
              
              Password Format:
              PSQL_<DB>_PASSWORD=password
              PSQL_<DB>_DEV_PASSWORD=dev_password
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
          enableTCPIP = true;
          dataDir = opts.dataDir;
          settings.port = opts.port;
          identMap = ''
            postgres roy postgres
          '';

          # allow remote connections to dev databases
          authentication = ''
            ${lib.concatStringsSep " " (map (db: "host ${db}_dev ${db}_devuser 10.0.0.141/24 md5\n") opts.databases) }
            ${lib.concatStringsSep " " (map (db: "local ${db} ${db}_produser md5\n") opts.databases) }
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

                dev_user_var="PSQL_''${db_upper}_DEV_USER"
                dev_pass_var="PSQL_''${db_upper}_DEV_PASSWORD"

                user_val="$db"_produser
                pass_val=$(eval "echo \''${$pass_var:-}")
                dev_user_val="$db"_devuser
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

                # Create databases if not exists
                if $psql_bin -c "\l" | grep -ci ""$db" "; then
                  echo "$db already exists, skipping creation."
                else
                  echo "Creating database $db"
                  $psql_bin -c "CREATE DATABASE "$db";"
                fi

                if $psql_bin -c "\l" | grep -ci "$db"_dev; then
                  echo ""$db"_dev already exists, skipping creation."
                else
                  echo "Creating database "$db"_dev"
                  $psql_bin -c "CREATE DATABASE "$db"_dev;"
                fi

                # Create users if not exists
                if $psql_bin -c "\du" | grep -ci "$user_val"; then
                  echo "$user_val already exists, skipping creation. WARN: password may not be correct. Delete user and allow to be recreated for assurity"
                else
                  echo "Creating $user_val"
                  $psql_bin -c "CREATE ROLE "$user_val" WITH LOGIN PASSWORD '$pass_val';"
                fi

                if $psql_bin -c "\du" | grep -ci "$dev_user_val"; then
                  echo "$dev_user_val already exists, skipping creation. WARN: password may not be correct. Delete user and allow to be recreated for assurity"
                else
                  echo "Creating $dev_user_val"
                  $psql_bin -c "CREATE ROLE "$dev_user_val" WITH LOGIN PASSWORD '$dev_pass_val';"
                fi

                # Give users privileges on databases (always)
                $psql_bin -c "GRANT ALL PRIVILEGES ON DATABASE "$db" TO "$user_val";"
                $psql_bin -c "GRANT ALL PRIVILEGES ON DATABASE "$db"_dev TO "$dev_user_val";"

              done
            '';
            };
          };

          networking.firewall.allowedTCPPorts = lib.mkIf opts.enable opts.port;
      };
    };
  };
}
