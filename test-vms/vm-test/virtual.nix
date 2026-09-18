{
  config,
  pkgs,
  meta,
  ...
}:
{

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  # Allow login and remote control of VM
  users.users.admin = {
    isNormalUser = true;
    hashedPassword = "$y$j9T$WI7E.NXw4qar1DXodrVWG/$gUErw1R6W8k1UFm49C5.vEc9MT5RcKW0BKitURNqbl/";
    extraGroups = [ "wheel" ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAcofS7u0BYzRBn0i4RuXPHWpnvk3nEbGo9B9ghsR4oL roydumblauskas@gmail.com"
    ];
  };

  # Don't allow password login
  services.openssh = {
    enable = true;

    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Packages
  environment.systemPackages = with pkgs; [
    curl
    kitty
    nginx
    tmux
    vim
    wget
  ];

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

    secrets = {
      "postgresql-credentials" = {
        sopsFile = ./secrets/psql.yaml;
        key = "credentials";
        format = "yaml";
        owner = "postgres";
        group = "postgres";
      };
    };
  };

  systemd.user.services.mbsync.unitConfig.After = [ "sops-nix.service" ];

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
    credentialsFile = config.sops.secrets."postgresql-credentials".path;
    databases = [
      "test"
    ];
    ipMasks = [
      "10.42.0.0/20" # k3s pod mask
    ];
  };

  # To stop the complaining
  system.stateVersion = "26.05";

}
