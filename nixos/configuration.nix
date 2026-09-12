{
  config,
  pkgs,
  meta,
  ...
}:
{
  imports = [ ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  # Secret Management
  sops = {
    # make sure that the age key is generated from the persisted host key
    age = {
      sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/persist/var/lib/sops-nix/key.txt";
      generateKey = true;
    };

    # I prefer to use json format for the secrets
    defaultSopsFormat = "json";

    # Define file and key for each secret
    secrets = {
      "cloudflare-api-email" = {
        sopsFile = ./secrets/cloudflare.json;
        key = "CF_API_EMAIL";
        owner = "acme";
        group = "acme";
      };

      "cloudflare-api-key" = {
        sopsFile = ./secrets/cloudflare.json;
        key = "CF_API_KEY";
        owner = "acme";
        group = "acme";
      };

      "postgresql-credentials" = {
        sopsFile = ./secrets/psql.yaml;
        key = "credentials";
        format = "yaml";
        owner = "postgres";
        group = "postgres";
      };

      "gitea-credentials" = {
        sopsFile = ./secrets/gitea.yaml;
        key = "credentials";
        format = "yaml";
        owner = "root";
        group = "root";
      };
    };
  };

  systemd.user.services.mbsync.unitConfig.After = [ "sops-nix.service" ];
  fileSystems."/persist".neededForBoot = true;

  # Set up https certs via cloudflare/acme
  security.acme = {
    acceptTerms = true;
    defaults = {
      # use staging for testing
      # server = "https://acme-staging-v02.api.letsencrypt.org/directory";
      # use prod for deploy
      server = "https://acme-v02.api.letsencrypt.org/directory";
      email = "roydumblauskas@gmail.com";
      dnsProvider = "cloudflare";
      # When the service CHECKS to see if certs are near expiry (< 30 days)
      renewInterval = "daily";
      credentialFiles = {
        CF_API_EMAIL_FILE = config.sops.secrets."cloudflare-api-email".path;
        CF_API_KEY_FILE = config.sops.secrets."cloudflare-api-key".path;
      };
    };

    certs = {
      "roypository.com" = {
        domain = "roypository.com";
        extraDomainNames = [ "*.roypository.com" ];
        group = "nginx";
      };
    };

  };

  # This deploys to the k3s cluster declared below
  services.nimh-static = {
    enable = true;

    default-nginx = {
      enable = true;
      hostname = "nimh.roypository.com";
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
      "--data-dir=/persist/var/lib/rancher/k3s"
      "--cluster-cidr 10.42.0.0/20"
    ];
  };

  # ================================ #
  #          END K3S SERVICE         #
  # ================================ #
  # ================================ #
  #           GITEA SERVICE          #
  # ================================ #

  services.hl-gitea = {
    enable = true;
    credentialsFile = config.sops.secrets."gitea-credentials".path;
    database-hostname = "${config.ipAddrs.${meta.hostname}}:5432"; # whatever port I host psql on below

    default-nginx = {
      enable = true;
      hostname = "roypository.com";
    };
  };

  # ================================ #
  #           GITEA SERVICE          #
  # ================================ #
  # ================================ #
  #           BLOG SERVICE           #
  # ================================ #

  # fullstack code. Dev hosted via VMs (incus)

  # ================================ #
  #         END BLOG SERVICE         #
  # ================================ #
  # ================================ #
  #           PSQL SERVICE           #
  # ================================ #

  # Postgresql/postgrest for row storage (not on k3s)
  services.postgresql-db = {
    enable = true;
    dataDir = "/persist/var/lib/postgresql";
    port = 5432;
    credentialsFile = config.sops.secrets."postgresql-credentials".path;
    databases = [
      "gitea"
    ];
    ipMasks = [
      "10.42.0.0/20" # k3s pod mask
    ];
  };

  # ================================ #
  #         END PSQL SERVICE         #
  # ================================ #

  # ================================ #
  #             MINECRAFT            #
  # ================================ #

  services.mc-service = {
    enable = true;
    storeDir = "/persist/srv/minecraft";
  };

  # ================================ #
  #             END MINECRAFT        #
  # ================================ #

  # Grub Boot Loader Setup
  boot.loader.grub = {
    enable = true;
    zfsSupport = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    configurationLimit = 25;
    mirroredBoots = [
      {
        devices = [ "nodev" ];
        path = "/boot";
      }
    ];
  };

  boot.zfs.forceImportRoot = false;

  # Delete root on reboot
  boot.initrd.systemd.services = {
    rollback = {
      description = "Rollback root zfs dataset to blank snapshot";
      wantedBy = [ "initrd.target" ];
      before = [ "sysroot.mount" ];
      after = [ "zfs-import-zroot.service" ];
      path = [ pkgs.zfs ];

      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";

      script = ''
        zfs rollback -r zroot/root@blank
        echo "blank rollback complete" > /dev/kmsg
      '';
    };
  };

  # Setup Incus daemon on boot
  # Init with `incus admin init --minimal`
  virtualisation.incus.enable = true;

  networking = {
    hostName = meta.hostname;
    hostId = meta.hostId;
    defaultGateway = "192.168.8.1";
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
    nftables.enable = true;

    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
        443
        6443 # k3s
      ];

      # Trust all incusVMs (on this network interface)
      trustedInterfaces = [ "incusbr0" ];
    };

    interfaces.eth0.ipv4.addresses = [
      {
        address = config.ipAddrs.${meta.hostname};
        prefixLength = 24;
      }
    ];
  };

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.roy = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "incus-admin"
    ];
    hashedPassword = "$y$j9T$qHYfvijvytC69cjEWTHYA/$YF6ig1hNvkTQi0UffZP1dpilS.8O28qEY4bfdvRTXYA";
    # laptop and desktop
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFEQyjykrRpkgMFpNAR2G1rbofqbtcuLwIYzgqH85QCn roydumblauskas@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPERQEHVwrtsWOpu1BgT7b1WNe4ShCy4bXWoGWvYENBw roydumblauskas@gmail.com"
    ];
    shell = pkgs.fish;
  };

  users.users.root = {
    # laptop and desktop
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFEQyjykrRpkgMFpNAR2G1rbofqbtcuLwIYzgqH85QCn roydumblauskas@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPERQEHVwrtsWOpu1BgT7b1WNe4ShCy4bXWoGWvYENBw roydumblauskas@gmail.com"
    ];
  };

  # Symlink the user directories that need to be persisted (ssh key/repository folder)
  environment.persistence."/persist" = {
    directories = [
      "/root/.ssh"
      "/var/lib/nixos"
      "/var/db/sudo/lectured"
    ];
  };

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    curl
    kitty
    nginx
    tmux
    vim
    wget
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.mononoki
    nerd-fonts.ubuntu-mono
  ];

  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    waybar.enable = true;
    fish.enable = true;
    fuse.userAllowOther = true;
  };

  environment.variables = {
    EDITOR = "nvim";
  };

  # List services that you want to enable:
  services.openssh = {
    enable = true;
    hostKeys = [
      {
        type = "ed25519";
        path = "/persist/etc/ssh/ssh_host_ed25519_key";
      }
      {
        type = "rsa";
        bits = 4096;
        path = "/persist/etc/ssh/ssh_host_rsa_key";
      }
    ];
  };

  # INITIAL system version
  system.stateVersion = "24.11";

}
