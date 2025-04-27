{ config, lib, pkgs, meta, ... }:

let
  testSiteIndex = pkgs.writeText "index.html" ''
    <html>
      <head><title>Hello</title></head>
      <body>
        <h1>Hello from test.roypository.com 🎉</h1>
        <p>This content is defined in configuration.nix</p>
      </body>
    </html>
  '';
in
{
  imports = [ ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Secret Management
  sops = {
    age.keyFile = "/etc/sops/age/keys.txt";
    defaultSopsFormat = "json";

    secrets = {
      "clusterPassword" = {
        sopsFile = ./secrets/build.json;
      };
      "cloudflare-api-email" = {
        sopsFile = ./secrets/cloudflare.json;
        key = "CF_API_EMAIL";
      };

      "cloudflare-api-key" = {
        sopsFile = ./secrets/cloudflare.json;
        key = "CF_API_KEY";
      };
    };
  };

  # make sure that the transfered sops key is moved to correct directory
  system.activationScripts.installSopsKey = {
    text = ''
      mkdir -p /etc/sops/age
      mv /tmp/keys.txt /etc/sops/age/keys.txt
      chmod 600 /etc/sops/age/keys.txt
    '';
  };

  systemd.user.services.mbsync.unitConfig.After = [ "sops-nix.service" ];
  
  environment.variables = {
    SECRETKEY = "${config.sops.secrets."clusterPassword".path}";
  };

  # set up DNS with nginx
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
  
  services.nginx.enable = true;

  services.nginx.virtualHosts."roypository.com" = {
    forceSSL = true;
    enableACME = true; 
    acmeRoot = null;
  };


  services.nginx.virtualHosts."test.roypository.com" = {
    forceSSL = true;
    enableACME = true;
    acmeRoot = null;
    root = "${testSiteIndex}";
    locations."/" = {
      extraConfig = ''
        index index.html;
      '';
    };
  };

  # Grub Boot Loader Setup
  boot.loader.grub = {
    enable = true;
    zfsSupport = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    mirroredBoots = [
      { devices = [ "nodev" ]; path = "/boot"; }
    ];
  };

  networking.hostName = meta.hostname;
  networking.hostId = meta.hostId;

  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = config.ipAddrs.${meta.hostname};
      prefixLength = 24;
    }
  ];

  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
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
    hashedPassword = "$6$8KRJ44z15XsQALM.$J4geTLaph7ynaLimlYXMGafqPOP6DONLSlTbRowH7JF7WJ4cWyMSTYQQB4OwsAgPpLCTYDzpqn6a/pfIizWFA.";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICNkZ5Xr75thR/tEgsASzYAtaA/kbsv2PKI8ux9rgpTe roydumblauskas@gmail.com"
    ];
  };
  
  users.users.root = {
    hashedPassword = "$y$j9T$IjaP0KIfdpEvlLtOn.u0T/$0MJDaFEdSu6zSJ04CF1dtorD6IVgbN3vmDiiwGwwqr5";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICNkZ5Xr75thR/tEgsASzYAtaA/kbsv2PKI8ux9rgpTe roydumblauskas@gmail.com" 
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    curl
    vim
    wget
  ];


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # INITIAL system version
  system.stateVersion = "24.11";

}
