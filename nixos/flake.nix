{
  description = "Server Config Controller";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixvim.url = "github:nix-community/nixvim";
    quasiSecrets.url = "git+ssh://git@github.com/RoyDumblauskas/server-semi-secrets";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
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
    # IDK if this is right, might need to import each service, hope not
    services = {
      url = "./services/";
    };
  };

  outputs = { self, nixpkgs, nixvim, home-manager, disko, sops-nix, quasiSecrets }@inputs: 
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
          (quasiSecrets.nixosModules)
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.sysAdmin = ./home.nix;
          }
        ];
      };      
    }) nodes);
  };
}
