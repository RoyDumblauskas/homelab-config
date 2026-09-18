{
  description = "Flake to run services on a VM powered by incus";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    postgresql-db.url = "path:../../homelab-services/postgresql-db";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      sops-nix,
      postgresql-db,
    }@inputs:
    {
      nixosConfigurations = {
        vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./virtual.nix
            postgresql-db.nixosModules.postgresql-db
            sops-nix.nixosModules.sops

            # declare the vm output
            "${inputs.nixpkgs}/nixos/modules/virtualisation/incus-virtual-machine.nix"
          ];
        };
      };
    };
}
