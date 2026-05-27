{
  description = "Flake that configures a static site hosted in a k3s pod";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = {
    nixosModules.nimh-static =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        opts = config.services.nimh-static;
      in
      {
        options.services.nimh-static = {
          enable = lib.mkEnableOption "serve nimh via k3s pod.";

          credentialsFile = lib.mkOption {
            type = lib.types.path;
            description = "File containing service (k3s) secrets.";
          };

          rootDir = lib.mkOption {
            type = lib.types.path;
            description = "Root of the static site";
          };

          default-nginx = {
            enable = lib.mkEnableOption "Enable nginx reverse proxy.";
            hostname = lib.mkOption {
              type = lib.types.str;
              default = "localhost";
              description = "Hostname for reverse proxy";
            };

          };
        };

        config = lib.mkIf opts.enable {
          users.groups.nimh = { };
          users.users.nimh = {
            isSystemUser = true;
            createHome = true;
            home = "${opts.rootDir}";
            group = "nimh";
          };

          systemd.services.nimh-static = {
            description = "oneshot apply service to k3s";
            after = [ "k3s.servce" ];
            wantedBy = [ "multi-user.target" ];

            serviceConfig = {
              Type = "oneshot";
              ExecStart = ''
                kubectl=${pkgs.kubectl}/bin/kubectl
                kubectl apply -k ./k3s


              '';

              User = "nimh";
              Group = "nimh";
              EnvironmentFile = "${opts.credentialsFile}";
            };
          };

          service.nginx = lib.mkIf opts.default-nginx.enable {
            enable = true;

            virtualHosts.${opts.default-nginx.hostname} = {
              forceSSL = true;

              # Parse TLD from hostname to use wildcard cert (just takes last two elements separated by a period)
              useACMEHost =
                let
                  b = builtins;
                  s = lib.strings;
                  fl = s.splitString "." "${opts.default-nginx.hostname}";
                in
                b.concatStringsSep "." [
                  (b.elemAt fl (b.length fl - 2))
                  (b.elemAt fl (b.length fl - 1))
                ];

              locations."/" = {
                # Default k3s port?
                proxyPass = "http://localhost:30080";
              };
            };
          };

          networking.firewall.allowedTCPPorts = lib.mkif opts.default-nginx.enable [
            80
            443
          ];
        };

      };
  };
}
