{ config, pkgs-unstable, ... }:
let
  domain = "cloud.jonrei.de";
  collaboraDomain = "office.jonrei.de";
  port = 9200;
in
{
  services.opencloud = {
    enable = true;
    package = pkgs-unstable.opencloud;
    url = "https://${domain}";
    address = "127.0.0.1";
    port = port;
    environment.PROXY_TLS = "false";
    environmentFile = config.age.secrets.opencloudAdminEnv.path;
    settings.csp.directives = {
      child-src       = [ "'self'" ];
      connect-src     = [ "'self'" "blob:" ];
      default-src     = [ "'none'" ];
      font-src        = [ "'self'" ];
      frame-ancestors = [ "'self'" ];
      frame-src       = [ "'self'" "blob:" "https://${collaboraDomain}" ];
      img-src         = [ "'self'" "data:" "blob:" ];
      manifest-src    = [ "'self'" ];
      media-src       = [ "'self'" ];
      object-src      = [ "'self'" "blob:" ];
      script-src      = [ "'self'" "'unsafe-inline'" ];
      style-src       = [ "'self'" "'unsafe-inline'" ];
    };
  };

  services.caddy.virtualHosts.${domain}.extraConfig = ''
    reverse_proxy http://127.0.0.1:${toString port}
    header Strict-Transport-Security "max-age=31536000"
  '';
}
