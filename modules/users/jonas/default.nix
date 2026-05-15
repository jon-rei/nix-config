{ pkgs, ... }:
{
  nix.settings.trusted-users = [ "jonas" ];

  users.users.jonas = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
    # TODO: replace with your SSH public key
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKF+wET8HXBy9tZXqI0ZNvtaXqqpEjNz8tNJD1nyJDjq"
    ];
  };

  home-manager.users.jonas = import ./dots.nix;
}
