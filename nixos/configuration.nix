{ config, lib, pkgs, meta, ... }:

{
  imports = [ ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
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
      };

      "cloudflare-api-key" = {
        sopsFile = ./secrets/cloudflare.json;
        key = "CF_API_KEY";
      };

      "minio-credentials" = {
        sopsFile = ./secrets/minio.yaml;
        key = "minioCredentials";
        format = "yaml";
      };

      "tests-service" = {
        sopsFile = ./secrets/tests-service.yaml;
        key = "credentials";
        format = "yaml";
      };
    };
  };

  systemd.user.services.mbsync.unitConfig.After = [ "sops-nix.service" ];
  fileSystems."/persist".neededForBoot = true;

  # Set up https certs via cloudflare/acme
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "roydumblauskas@gmail.com";
      dnsProvider = "cloudflare";
      credentialFiles = {
        CF_API_EMAIL_FILE = config.sops.secrets."cloudflare-api-email".path;
        CF_API_KEY_FILE = config.sops.secrets."cloudflare-api-key".path;
      };
    };
  };

  # Setup vhosts via nginx
  services.nginx = {
    enable = true;
    logError = "stderr";
    
    virtualHosts."roypository.com" = {
      forceSSL = true;
      enableACME = true; 
      acmeRoot = null;
    };
  };

  # Declare test service manually
  services.tests-service = {
    enable = true;
    port = 8080;
    credentialsFile = config.sops.secrets."tests-service".path;
    default-nginx = {
      enable = true;
      hostname = "test.roypository.com";
    };
  };

  # Declare minio service manually

  services.minio-service = {
    enable = true;

    # Persist data inside of database
    dataDir = "/data/minio";
    credentialsFile = config.sops.secrets."minio-credentials".path;

    dataPort = 9000;     # S3 API access
    consolePort = 9001;  # Admin console access

    bootstrap-minio = {
      enable = true;
      environments = [ "dev" "prod" ];
    };

    default-nginx = {
      enable = true;
      hostname = "imgs.roypository.com";
    };
  };

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
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    grub = {
      efiSupport = true;
      device = "nodev";
      configurationLimit = 3;
    };
  };

  # Rollback root on reboot
  boot.initrd.postMountCommands = lib.mkAfter ''
    zfs rollback -r zroot/root@blank
  '';
  
  networking = {
    hostName = meta.hostname;
    hostId = meta.hostId;
    defaultGateway = "10.0.0.1";
    nameservers = [ "1.1.1.1" "1.0.0.1" ];

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443];
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

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };


  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.sysAdmin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkManager" ];
    # created with mkpasswd
    hashedPassword = "$y$j9T$ILYm49Ylk4h6Wforpdw161$ds0DvzLQkbh0o3vN6D.gZ4KMo..0AOR/DwNcWtY0nH2";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFEQyjykrRpkgMFpNAR2G1rbofqbtcuLwIYzgqH85QCn roydumblauskas@gmail.com"
    ];
  };

  users.users.roy = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPassword = "$y$j9T$GigbbrHNEe.fhkEYbbYGc1$7dS10OH5LGoZtCfoDy82H71nZVbCgGHdkwVwxZpGUY4";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFEQyjykrRpkgMFpNAR2G1rbofqbtcuLwIYzgqH85QCn roydumblauskas@gmail.com"
    ];
    shell = pkgs.fish;
  };

  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFEQyjykrRpkgMFpNAR2G1rbofqbtcuLwIYzgqH85QCn roydumblauskas@gmail.com"
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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
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

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

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
