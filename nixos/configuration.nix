{ config, lib, pkgs, meta, ... }:

{
  imports = [ ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Secret Management
  sops = {
    age.keyFile = "./age/keys.txt"; # Make sure to gitignore, contains private key.

    defaultSopsFile = ./secrets/build.json;
    defaultSopsFormat = "json";

    secrets."nixos-homelab-00" = { };
  };

  systemd.user.services.mbsync.unitConfig.After = [ "sops-nix.service" ];

  # Use the systemd-boot EFI boot loader.
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

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

  networking.hostname = meta.hostname;

  let
    addresses = import ./ip-addresses.nix;
  in {
    networking.interfaces.eth0.ipv4.addresses = [
      {
        address = addresses.${meta.hostname};
        prefixLength = 24;
      }
    ];

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

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # INITIAL system version
  system.stateVersion = "24.11";

}
