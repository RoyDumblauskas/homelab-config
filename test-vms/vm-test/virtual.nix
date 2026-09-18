{
  config,
  pkgs,
  meta,
  ...
}:
{

  # Allow login and remote control of VM
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAcofS7u0BYzRBn0i4RuXPHWpnvk3nEbGo9B9ghsR4oL roydumblauskas@gmail.com"
    ];
  };

  # ================================ #
  #               SOPS               #
  # ================================ #

  sops = {
    # make sure that the age key is generated from the persisted host key
    age = {
      sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/persist/var/lib/sops-nix/key.txt";
      generateKey = true;
    };

    defaultSopsFormat = "yaml";

    "postgresql-credentials" = {
      sopsFile = ./secrets/psql.yaml;
      key = "credentials";
      format = "yaml";
      owner = "postgres";
      group = "postgres";
    };

  };

  # ================================ #
  #            K3S SERVICE           #
  # ================================ #

  services.k3s = {
    enable = true;
    disable = [ "traefik" ];
    role = "server";

    # only enable the service on k3s when roughly finalized
    # Until then use a vm, as k3s is persisted
    extraFlags = [
      "--data-dir=/var/lib/rancher/k3s"
      "--cluster-cidr=10.42.0.0/20"
    ];
  };

  # ================================ #
  #           PSQL SERVICE           #
  # ================================ #

  # Postgresql/postgrest for row storage (not on k3s)
  services.postgresql-db = {
    enable = true;
    dataDir = "/var/lib/postgresql";
    port = 5432;
    credentialsFile = ./secrets/ex-psql.yaml;
    databases = [
      "test"
    ];
    ipMasks = [
      "10.42.0.0/20" # k3s pod mask
    ];
  };

}
