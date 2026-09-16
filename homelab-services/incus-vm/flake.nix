{
  description = "Flake to run services on a VM powered by incus";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    postgres-db.url = "path:../postgresql-db";
  };

  outputs =
    {
      self,
      nixpkgs,
      postgres-db,
    }@inputs:
    {
      nixosConfigurations = {
        name = "virtual-env";
        value = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./virtual.nix
            postgres-db.nixosModules.postgres-db
          ];
        };
      };
    };
}
