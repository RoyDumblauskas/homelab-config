{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

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

  # zfs File System Declaration  

  fileSystems."/" = {
    device = "zpool/root";
    fsType = "zfs";
  };

  fileSystems."/nix" = {
    device = "zpool/nix";
    fsType = "zfs";
  };

  fileSystems."/var" = {
    device = "zpool/var";
    fsType = "zfs";
  };

  fileSystems."/home" = {
    device = "zpool/home";
    fsType = "zfs";
  };

  fileSystems."/boot" ={
    device = "/dev/disk/by-uuid/8D3A-0C41";
    fsType = "vfat";
  };

  swapDevices = [ ];

  networking.hostName = "nixos";
  networking.hostId = "4cb9fc76";

  networking.wireless = {
    enable = true;
    networks."flooper".pskRaw = "3ac6f88df2b7de61e98a0c6f95c34f7ca5f96593065a98e1200a3931219801b3";
    networks."NU-Guest" = {
      priority = -1;
    };
    networks.eduroam = {
      priority = -2;
      auth = ''
        key_mgmt=WPA-EAP
        eap=PEAP
        identity="rdumblauskas2@unl.edu"
        password="******"
      '';
    };
    extraConfig = "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=wheel";
  };

  networking.wireless.userControlled.enable = true; # Enable user to edit wpa_supplicant.
  networking.networkmanager.enable = false;  # Easiest to use and most distros use this by default.

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

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.roy = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  users.users.net = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    packages = with pkgs; [
      tree
      git
    ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    gimp
    kitty
    rose-pine-hyprcursor
    vim
    wget
  ];

  fonts.packages = with pkgs; [ nerdfonts ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  programs.hyprland = {
   enable = true;
   xwayland.enable = true;
  };

  programs.waybar.enable = true;

  programs.firefox = {
    enable = true;
    policies = {
      ExtensionSettings = {
        "*".installation_mode = "blocked";
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # INITIAL system version
  system.stateVersion = "24.11";

}

