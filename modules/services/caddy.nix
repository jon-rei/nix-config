{ config, lib, inputs, ... }:
{
  options.caddy = {
    enable = lib.mkEnableOption "Caddy web server";

    acmeDomains = lib.mkOption {
      type    = lib.types.listOf lib.types.str;
      default = [];
      description = "Base domains to get wildcard certs for via deSEC DNS challenge.";
    };
  };

  config = lib.mkIf config.caddy.enable {
    motd.services = [ "caddy" ];
    age.secrets.desecEnv = {
      file  = "${inputs.self}/secrets/desec-env.age";
      owner = "acme";
    };

    security.acme = {
      acceptTerms = true;
      defaults = {
        email           = "mail@jonrei.de";
        dnsProvider     = "desec";
        dnsResolver     = "ns1.desec.io:53";
        environmentFile = config.age.secrets.desecEnv.path;
        reloadServices  = [ "caddy.service" ];
      };
      certs = builtins.listToAttrs (map (domain: {
        name  = domain;
        value = {
          extraDomainNames = [ "*.${domain}" ];
          group            = config.services.caddy.group;
        };
      }) config.caddy.acmeDomains);
    };

    services.caddy = {
      enable       = true;
      globalConfig = "auto_https off";
      logFormat = ''
        output stderr
      '';
      virtualHosts = builtins.listToAttrs (lib.flatten (map (domain: [
        { name  = "http://${domain}";
          value = { extraConfig = "redir https://{host}{uri}"; }; }
        { name  = "http://*.${domain}";
          value = { extraConfig = "redir https://{host}{uri}"; }; }
      ]) config.caddy.acmeDomains));
    };
  };
}
