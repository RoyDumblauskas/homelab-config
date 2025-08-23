{
  description = "Server Config Controller";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quasiSecrets.url = "git+ssh://git@github.com/RoyDumblauskas/server-semi-secrets?shallow=1";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # This is a path to the services I've declared. 
    # It just happens to be stored in the same repository (relative), 
    # but could well be a separate repository
    tests-service.url = "github:RoyDumblauskas/tests-service?shallow=1";
    minio-service.url = "path:../homelab-services/minio-service";
    mc-service.url = "path:../homelab-services/mc-service";
  };

  outputs = { self, nixpkgs, nixvim, home-manager, disko, sops-nix, quasiSecrets, impermanence, firefox-addons, tests-service, minio-service, mc-service }@inputs: 
  let 
    nodes = [
      { 
        name = "nixos-homelab-00";
        hostId = "3884D2F1";
      }
    ];
  in {
    nixosConfigurations = builtins.listToAttrs (map (node: {
      name = node.name;
      value = nixpkgs.lib.nixosSystem {
        specialArgs = {
          meta = {
            hostname = node.name;
            hostId = node.hostId;
          };
        };
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./hardware-configuration.nix
          ./disk-config.nix
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          quasiSecrets.nixosModules.ipAddrs
          quasiSecrets.nixosModules.serviceList
          impermanence.nixosModules.impermanence
          tests-service.nixosModules.default
          minio-service.nixosModules.minio-service
          mc-service.nixosModules.mc-service
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.sysAdmin = ./home.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.roy = { ... }: {
              imports = [
                ./home-roy.nix
                nixvim.homeManagerModules.nixvim
                impermanence.homeManagerModules.impermanence
                sops-nix.homeManagerModules.sops
              ];
            };
          }
        ];
      };      
    }) nodes);
  };
}
