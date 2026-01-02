# NixOS Configuration - Iris
# Workstation + Development + Gaming

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Add the boot parameters needed for NVIDIA
  boot.kernelParams = [ "nomodeset" "acpi=off" "amd_iommu=off" ];

  # Networking
  networking.hostName = "iris";
  networking.networkmanager.enable = true;
  networking.firewall = {
    allowedTCPPorts = [ 47984 47989 47990 48010 ];
    allowedUDPPorts = [ 47998 47999 48000 48010 ];
  };

  # enable uinput for virtual input (allows remote keyboard/mouse)
  boot.kernelModules = [ "uinput" ];

  services.udev.extraRules = ''
    KERNEL=="uinput", SUBSYSTEM=="misc", MODE="0660", GROUP="input"
  '';

  # Locale and Time
  time.timeZone = "America/Boise";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";

  # Enable NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;
  };

  # Hardware Configuration
  hardware = {
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;

      # Use open source kernel module (false = proprietary)
      open = false;

      # Enable settings menu
      nvidiaSettings = true;

      # Select driver package (stable is recommended)
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    graphics = {
      enable = true;
      enable32Bit = true;
    };

    bluetooth.enable = true;
  };

  # Security
  security = {
    polkit.enable = true;
    rtkit.enable = true;  # Required for PipeWire
  };

  # Swap
  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  # Audio - PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # X Server with KDE Plasma
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Users
  users.users.teapot = {
    isNormalUser = true;
    description = "Talmage Potts";
    extraGroups = [ "wheel" "networkmanager" "docker" "audio" "video" "input" ];
    shell = pkgs.zsh;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
    # Core utilities
    vim
    neovim
    wget
    curl
    git
    rsync
    unzip
    htop
    btop
    tree
    claude-code

    # Development Languages - Python
    python3
    python3Packages.pip
    python3Packages.pandas
    python3Packages.requests
    python3Packages.virtualenv

    # Development Languages - Elixir & Erlang
    elixir
    erlang

    # Node.js & JavaScript
    nodejs_22
    nodePackages.npm
    nodePackages.yarn
    nodePackages.pnpm

    # Database tools
    pgcli           # Better PostgreSQL CLI
    dbeaver-bin     # GUI database manager

    # Version managers
    mise

    # Development tools
    gh
    lazygit

    # Docker tools
    docker-compose
    lazydocker

    # System tools
    btrfs-progs
    inetutils
    bash-completion
    pciutils
    mesa-demos
    vulkan-tools

    # For VNC sessions
    tigervnc

    # Minimal X utilities
    xorg.xinit
    xterm
    sunshine # Streaming host

    # File managers
    ranger
    pcmanfm

    # Web browser
    firefox
    brave

    # Nice-to-haves
    tmux          # Terminal multiplexer
    jq            # JSON processor
    ripgrep       # Fast grep (rg command)
    fzf           # Fuzzy finder
    bat           # Better cat with syntax highlighting
    zoxide
    oh-my-zsh
    zsh-powerlevel10k
  ];

  # Enable Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  # Enable Zsh
  programs.zsh.enable = true;

  # Bash with useful aliases
  programs.bash = {
    completion.enable = true;
    shellAliases = {
      ll = "ls -lah";
      ".." = "cd ..";
      dps = "docker ps";
      dcu = "docker-compose up -d";
      dcd = "docker-compose down";
      rebuild = "sudo nixos-rebuild switch";
      update = "sudo nixos-rebuild switch --upgrade";
    };
  };

  # Git configuration
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
    };
  };

  # Fonts (needed for Powerlevel10k and GUI apps)
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
  ];

  # Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # Services
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    extraUpFlags = [ "--ssh" ];
  };
  
  # Add this to your desktop's configuration.nix
  systemd.user.services.sunshine = {
    description = "Sunshine streaming server";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.sunshine}/bin/sunshine";
      Restart = "on-failure";
    };
  };

  # Enable flakes and auto-optimization
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
