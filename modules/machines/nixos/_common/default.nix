{ config, pkgs, lib, ... }:
{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # agenix decrypts secrets at boot using the SSH host key.
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  programs.git.enable = true;

  system.autoUpgrade = {
    enable = true;
    flake = "git+https://codeberg.org/jonrei/nix-config#${config.networking.hostName}";
    flags = [ "-L" ];
    dates = "*-*-* 03:30:00";
    allowReboot = true;
  };

  security.sudo.wheelNeedsPassword = false;

  services.resolved = {
    enable = true;
    dnssec = "true";
    dnsovertls = "opportunistic";
  };

  networking.nameservers = [
    "9.9.9.9#dns.quad9.net"
    "149.112.112.112#dns.quad9.net"
    "2620:fe::fe#dns.quad9.net"
    "2620:fe::9#dns.quad9.net"
  ];

  system.stateVersion = "25.11";

  environment.systemPackages = with pkgs; [
    nano
    git
    htop
    curl
    wget
    tmux
    lsof
    iotop
    dnsutils
    unixtools.netstat
    mtr
  ];
}
