{
  description = "Flake to run services on a VM powered by incus";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    postgresql-db = {
      url = "path:../../homelab-services/postgresql-db";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      postgresql-db,
    }@inputs:
    let
      credentials = builtins.listToAttrs (
        map (filename: {
          name = builtins.replaceStrings [ ".env" ] [ "-env" ] filename;
          value = nixpkgs.runCommand "sops-decrypt-${filename}" { } ''
            ${nixpkgs.sops}/bin/sops -d ${./secrets}/${filename} > $out
          '';
        }) (builtins.attrNames (builtins.readDir ./secrets))
      );
    in
    {
      nixosConfigurations = {
        vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit credentials;
          };
          modules = [
            ./virtual.nix
            postgresql-db.nixosModules.postgresql-db

            # declare the vm output
            "${inputs.nixpkgs}/nixos/modules/virtualisation/incus-virtual-machine.nix"
          ];
        };
      };
    };
}
