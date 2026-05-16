{ pkgs, ... }:
{
  nix.settings.trusted-users = [ "jonas" ];

  home-manager.users.jonas = import ./dots.nix;

  programs.zsh.enable = true;

  users.users.jonas = {
    isNormalUser = true;
    uid = 1000;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKF+wET8HXBy9tZXqI0ZNvtaXqqpEjNz8tNJD1nyJDjq"
    ];
  };
}
