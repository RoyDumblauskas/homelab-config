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
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
      credentials = builtins.listToAttrs (
        map (filename: {
          name = builtins.replaceStrings [ ".env" ] [ "-env" ] filename;
          value =
            pkgs.runCommand "sops-decrypt-${filename}"
              {
                # Use special separate injectable key that can only decrypt these dummy secrets
                SOPS_AGE_KEY_FILE = "~/.config/sops/age/virtual-key.txt";
              }
              ''
                ${pkgs.sops}/bin/sops -d ${./secrets}/${filename} > $out
              '';
        }) (builtins.attrNames (builtins.readDir ./secrets))
      );
    in
    {
      nixosConfigurations = {
        vm = nixpkgs.lib.nixosSystem {
          system = system;
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
