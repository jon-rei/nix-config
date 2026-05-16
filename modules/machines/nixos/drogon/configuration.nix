{ config, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disko.nix
    ./secrets.nix
    ../../../services/caddy.nix
    ../../../services/opencloud.nix
    ../../../services/fail2ban.nix
  ];

  boot.loader.grub.enable = true;

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];

  zramSwap.enable = true;

  networking = {
    hostName = "drogon";
    domain = "dinoverse.de";
    useDHCP = true;
    interfaces.enp1s0.ipv6.addresses = [{
      address = "2a01:4f8:c014:573d::1";
      prefixLength = 64;
    }];
    defaultGateway6 = {
      address = "fe80::1";
      interface = "enp1s0";
    };

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ];
    };
  };

  backup = {
    enable = true;
    storageBox     = "u525833.your-storagebox.de";
    storageBoxUser = "u525833";
    paths = [
      config.services.opencloud.stateDir
    ];
  };
}
