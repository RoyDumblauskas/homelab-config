{
  description = "Flake that configures a static site hosted in a k3s pod";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs =
    { self, nixpkgs, ... }:
    {
      nixosModules.nimh-static =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          k3sDir = ./k3s;
          siteDir = ./site;
          opts = config.services.nimh-static;
        in
        {
          options.services.nimh-static = {
            enable = lib.mkEnableOption "serve nimh via k3s pod.";

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
              createHome = false;
              group = "nimh";
            };

            systemd.services.nimh-static = {
              description = "oneshot apply service to k3s";
              after = [ "k3s.service" ];
              wantedBy = [ "multi-user.target" ];

              serviceConfig = {
                Type = "oneshot";
                ExecStart = pkgs.writeShellScript "start-nimh-static" ''
                  echo "Creating temp dir"
                  kubernetes_config=$(mktemp -d)
                  echo "Generating templated files"
                  echo "${k3sDir}"
                  gomplate=${pkgs.gomplate}/bin/gomplate
                  $gomplate --input-dir=${k3sDir} --output-dir=$kubernetes_config -d site=file://${siteDir}/index.html
                  echo "Applying k3s config"
                  kubectl=${pkgs.kubectl}/bin/kubectl
                  $kubectl apply -k $kubernetes_config
                '';

                User = "nimh";
                Group = "nimh";
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
                  # Default k3s port?
                  proxyPass = "http://localhost:30080";
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
