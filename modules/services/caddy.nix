{ ... }:
let
  site1 = "jonrei.de";
  site2 = "example2.com";  # TODO: replace
in
{
  services.caddy.enable = true;

  # services.caddy.virtualHosts.${site1}.extraConfig = ''
  #   root * /var/www/${site1}
  #   file_server
  #   encode gzip
  # '';

  # services.caddy.virtualHosts.${site2}.extraConfig = ''
  #   root * /var/www/${site2}
  #   file_server
  #   encode gzip
  # '';
}
