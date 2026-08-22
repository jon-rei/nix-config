{
  config,
  lib,
  inputs,
  ...
}:
{
  options.caddy = {
    enable = lib.mkEnableOption "Caddy web server";

    acmeDomains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Base domains to get wildcard certs for via deSEC DNS challenge.
        Use this when several subdomains of one base domain share a host
        (e.g. cloud/office on jonrei.de) or for hosts not reachable from the
        internet, where Caddy's normal HTTP-01 automatic HTTPS can't work.
        Standalone public domains should leave this empty and rely on
        Caddy's automatic HTTPS instead.
      '';
    };
  };

  config = lib.mkIf config.caddy.enable {
    motd.services = [ "caddy" ];

    age.secrets.desecEnv = lib.mkIf (config.caddy.acmeDomains != [ ]) {
      file = "${inputs.self}/secrets/desec-env.age";
      owner = "acme";
    };

    security.acme = lib.mkIf (config.caddy.acmeDomains != [ ]) {
      acceptTerms = true;
      defaults = {
        email = "mail@jonrei.de";
        dnsProvider = "desec";
        dnsResolver = "ns1.desec.io:53";
        environmentFile = config.age.secrets.desecEnv.path;
        reloadServices = [ "caddy.service" ];
      };
      certs = builtins.listToAttrs (
        map (domain: {
          name = domain;
          value = {
            extraDomainNames = [ "*.${domain}" ];
            group = config.services.caddy.group;
          };
        }) config.caddy.acmeDomains
      );
    };

    services.caddy = {
      enable = true;
      logFormat = ''
        output stderr
      '';
      virtualHosts = builtins.listToAttrs (
        lib.flatten (
          map (domain: [
            {
              name = "http://${domain}";
              value = {
                extraConfig = "redir https://{host}{uri}";
              };
            }
            {
              name = "http://*.${domain}";
              value = {
                extraConfig = "redir https://{host}{uri}";
              };
            }
          ]) config.caddy.acmeDomains
        )
      );
    };
  };
}
