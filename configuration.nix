{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  nix = {
    gc.automatic = true;
    optimise.automatic = true;
    autoOptimiseStore = true;
  };

  boot.loader = {
    grub = {
      enable = true;
      version = 2;
      device = "/dev/sdb";
      efiSupport = true;
    };
    systemd-boot = {
      editor = false;
      enable = true;
    };
    efi.canTouchEfiVariables = true;
  };

  power.ups = {
    enable = true;
    mode = "standalone";
    ups.local_ups = {
      description = "sven pro 650";
      driver = "blazer_usb";
      port = "auto";
    };
  };

  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  time.timeZone = "Europe/Minsk";

  environment.systemPackages = with pkgs; [
    neovim
    git
    htop
    tree
    wget
    gnumake
    traceroute
    mkpasswd
  ];

  services = {
    xserver.enable = false;
    openssh = {
      enable = true;
      passwordAuthentication = false;
      challengeResponseAuthentication = false;
    };
    nginx.enable = true;
    udev.extraRules = (import ./priv/ups/udev.rules);
  };

  virtualisation = {
    docker.enable = true;
  };

  programs.ssh.startAgent = true;

  networking.networkmanager.enable = true;

  networking.interfaces.eth0.ipv4.addresses = [ {
    address = "192.168.100.2";
    prefixLength = 24;
  } ];

  networking.defaultGateway = "192.168.100.1";

  networking.hostName = "server";

  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [ 8000 8080 ];
    allowedTCPPortRanges = [ { from = 9990; to = 9999; } ];
  };

  systemd.services.jsapp = {
    enable = true;
    after = [ "network.target" ];
    script = "/etc/profiles/per-user/verrchu/bin/node /home/verrchu/server/index.js";
    wantedBy = [ "multi-user.target" ];
  };

  users.users = {
    verrchu = {
      isNormalUser = true;
      description = "Yauheni Tsiarokhin <hihihiko00@gmail.com>";
      extraGroups = [ "wheel" "networkmanager" "docker" ];
      hashedPassword = (import ./priv/passwords/verrchu-passwd.nix);
      openssh.authorizedKeys.keys = [
        (import ./priv/ssh_keys/mobile.nix)
        (import ./priv/ssh_keys/personal.nix)
        (import ./priv/ssh_keys/wg_personal.nix)
      ];
      packages = with pkgs; [
        nodejs irssi tmux mc
        gcc ag fzf usbutils groff
        docker_compose docker-machine
      ];
    };
    nut = {
      uid = 84;
      home = "/var/lib/nut";
      createHome = true;
      group = "nut";
      description = "UPnP A/V Media Server user";
    };
  };

  users.groups = {
    nut = {
      gid = 84;
    };
  };

  system.stateVersion = "19.03";
}
