{
  config,
  pkgs,
  meta,
  credentials,
  ...
}:
let
  ipSubnet = "192.168.8";
  ipAddr = "170";
  k3sMask = "10.42.16.0/20";
in
{

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;

  # Allow login and remote control of VM
  users.users.admin = {
    isNormalUser = true;
    hashedPassword = "$y$j9T$WI7E.NXw4qar1DXodrVWG/$gUErw1R6W8k1UFm49C5.vEc9MT5RcKW0BKitURNqbl/"; # tmp
    extraGroups = [ "wheel" ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAcofS7u0BYzRBn0i4RuXPHWpnvk3nEbGo9B9ghsR4oL roydumblauskas@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPERQEHVwrtsWOpu1BgT7b1WNe4ShCy4bXWoGWvYENBw roydumblauskas@gmail.com"
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

  # Networking
  networking = {
    nftables.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        6443 # k3s
      ];
    };

    defaultGateway = "${ipSubnet}.1";

    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];

    useDHCP = false;

    interfaces.eth0.ipv4.addresses = [
      {
        address = "${ipSubnet}.${ipAddr}";
        prefixLength = 24;
      }
    ];
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

  # Set up https certs via cloudflare/acme
  security.acme = {
    acceptTerms = true;
    defaults = {
      # use staging for testing
      server = "https://acme-staging-v02.api.letsencrypt.org/directory";
      # use prod for deploy
      # server = "https://acme-v02.api.letsencrypt.org/directory";
      email = "roydumblauskas@gmail.com";
      dnsProvider = "cloudflare";
      # When the service CHECKS to see if certs are near expiry (< 30 days)
      renewInterval = "daily";
      credentialFiles = {
        CF_API_EMAIL_FILE = credentials.cloudflare-email-env;
        CF_API_KEY_FILE = credentials.cloudflare-key-env;
      };
    };

    certs = {
      "roypository.com" = {
        domain = "virtual.roypository.com";
        group = "nginx";
      };
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
      "--cluster-cidr=${k3sMask}"
    ];
  };

  # ================================ #
  #           GITEA SERVICE          #
  # ================================ #

  services.hl-gitea = {
    enable = true;
    credentialsFile = credentials.gitea-env;
    database-hostname = "${ipSubnet}.${ipAddr}:5432";

    default-nginx = {
      enable = true;
      hostname = "dummy.roypository.com";
    };
  };

  # ================================ #
  #           PSQL SERVICE           #
  # ================================ #

  # Postgresql/postgrest for row storage (not on k3s)
  services.postgresql-db = {
    enable = true;
    dataDir = "/var/lib/postgresql";
    port = 5432;
    credentialsFile = credentials.psql-env;
    databases = [
      "gitea"
    ];
    ipMasks = [
      k3sMask # k3s pod mask
    ];
  };

  # To stop the complaining
  system.stateVersion = "26.05";

}
