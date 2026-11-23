{
  description = "Expose Leantime nixos flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    { ... }:
    {
      nixosModules.leantime =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          k3sDir = ./k3s;
          opts = config.services.leantime;
        in
        {
          options.services.leantime = {
            enable = lib.mkEnableOption "Run Leantime on k3s";

            default-nginx = {
              enable = lib.mkEnableOption "Enable nginx reverse proxy.";
              hostname = lib.mkOption {
                type = lib.types.str;
                default = "localhost";
                description = "Hostname for reverse proxy";
              };
            };

            database-host = lib.mkOption {
              type = lib.types.str;
              description = ''
                host of external db (192.168.x.x). 
                On my machine will be semi-secret ip addr
              '';
            };

            database-port = lib.mkOption {
              type = lib.types.str;
              default = "5432";
              description = ''
                Port of psql db (default 5432)
              '';
            };

            credentialsFile = lib.mkOption {
              type = lib.types.path;
              description = ''
                File containing needed credentials.
              '';
            };
          };

          config = lib.mkIf opts.enable {
            systemd.services.leantime = {
              description = "oneshot apply service to k3s";
              after = [ "k3s.service" ];
              wantedBy = [ "multi-user.target" ];

              serviceConfig = {
                Type = "oneshot";
                ExecStart = pkgs.writeShellScript "start-leantime" ''
                  set -euo pipefail

                  echo "Creating temp dir"
                  kubernetes_config=$(mktemp -d)

                  echo "Generating templated files"
                  gomplate=${pkgs.gomplate}/bin/gomplate
                  printf '{"db_host":"%s","db_port":"%s","web_host":"%s"}' \
                    "${opts.database-host}" \
                    "${opts.database-port}" \
                    "${opts.default-nginx.hostname}" | $gomplate \
                    --input-dir=${k3sDir} \
                    --output-dir=$kubernetes_config \
                    --datasource credentials=file://${opts.credentialsFile}?type=application/x-env \
                    --datasource config=stdin:?type=application/json

                  echo "Applying k3s config"
                  kubectl=${pkgs.kubectl}/bin/kubectl
                  $kubectl \
                    --kubeconfig=/etc/rancher/k3s/k3s.yaml \
                    apply -k $kubernetes_config
                '';

                # Only user/group that has access to kubectl apply
                User = "root";
                Group = "root";
              };
            };

            services.nginx = lib.mkIf opts.default-nginx.enable {
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
                  proxyPass = "http://127.0.0.1:30091";

                  extraConfig = ''
                    proxy_set_header Host $host;
                    proxy_set_header X-Forwarded-Host $host;
                    proxy_set_header X-Real-IP $remote_addr;
                    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                    proxy_set_header X-Forwarded-Proto $scheme;
                  '';
                };
              };
            };
            networking.firewall.allowedTCPPorts = lib.mkIf opts.default-nginx.enable [
              80
              443
            ];
          };
        };
    };

}
