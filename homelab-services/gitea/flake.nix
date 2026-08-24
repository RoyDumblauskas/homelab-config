{
  description = "Flake configured to render and deploy a k3s folder for homelab gitea";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    { ... }:
    {
      nixosModules.hl-gitea =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          k3sDir = ./k3s;
          opts = config.services.hl-gitea;
        in
        {
          options.services.hl-gitea = {
            enable = lib.mkEnableOption "Run Gitea in k3s";

            default-nginx = {
              enable = lib.mkEnableOption "Enable nginx reverse proxy.";
              hostname = lib.mkOption {
                type = lib.types.str;
                default = "localhost";
                description = "Hostname for reverse proxy";
              };
            };

            database-hostname = lib.mkOption {
              type = lib.types.str;
              description = ''
                hostname of external db (192.168.x.x:5432). 
                On my machine will be semi-secret ip addr + whatever port.
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
            systemd.services.hl-gitea = {
              description = "oneshot apply service to k3s";
              after = [ "k3s.service" ];
              wantedBy = [ "multi-user.target" ];

              serviceConfig = {
                Type = "oneshot";
                ExecStart = pkgs.writeShellScript "start-gitea" ''
                  set -euo pipefail

                  echo "Creating temp dir"
                  kubernetes_config=$(mktemp -d)

                  echo "Generating templated files"
                  gomplate=${pkgs.gomplate}/bin/gomplate
                  echo "${opts.database-hostname}" | $gomplate \
                    --input-dir=${k3sDir} \
                    --output-dir=$kubernetes_config \
                    --datasource credentials=file://${opts.credentialsFile}?type=application/x-env \
                    --datasource dbhostname=stdin:

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
                  proxyPass = "http://127.0.0.1:30081";

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
              2222
            ];
          };
        };
    };

}
