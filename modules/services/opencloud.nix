{ config, lib, pkgs-unstable, inputs, ... }:
let
  domain = "cloud.jonrei.de";
  collaboraDomain = "office.jonrei.de";
  port = 9200;
in
{
  options.opencloud.enable = lib.mkEnableOption "OpenCloud with Collabora";

  config = lib.mkIf config.opencloud.enable {
    age.secrets.opencloudEnv = {
      file  = "${inputs.self}/secrets/opencloud-env.age";
      owner = "opencloud";
    };

    services.opencloud = {
      enable = true;
      package = pkgs-unstable.opencloud;
      url = "https://${domain}";
      address = "127.0.0.1";
      port = port;
      environment = {
        PROXY_TLS                       = "false";
        OC_ADD_RUN_SERVICES             = "collaboration";
        COLLABORATION_APP_ADDR          = "http://127.0.0.1:9980";
        COLLABORATION_APP_INSECURE      = "true";
        COLLABORATION_WOPI_SRC          = "https://${domain}";
        COLLABORATION_APP_PROOF_DISABLE = "true";
      };
      environmentFile = config.age.secrets.opencloudEnv.path;
      settings.proxy.csp_config_file_location = "/etc/opencloud/csp.yaml";

      settings.csp.directives = {
        child-src       = [ "'self'" ];
        connect-src     = [ "'self'" "blob:" "https://${collaboraDomain}" "wss://${collaboraDomain}" "https://update.opencloud.eu/" ];
        default-src     = [ "'none'" ];
        font-src        = [ "'self'" ];
        frame-ancestors = [ "'self'" ];
        frame-src       = [ "'self'" "blob:" "https://${collaboraDomain}" "https://embed.diagrams.net" "https://docs.opencloud.eu" ];
        img-src         = [ "'self'" "data:" "blob:" "https://raw.githubusercontent.com/opencloud-eu/awesome-apps/" "https://tile.openstreetmap.org/" ];
        manifest-src    = [ "'self'" ];
        media-src       = [ "'self'" ];
        object-src      = [ "'self'" "blob:" ];
        script-src      = [ "'self'" "'unsafe-inline'" ];
        style-src       = [ "'self'" "'unsafe-inline'" ];
      };
    };

    virtualisation.oci-containers.containers.collabora = {
      image = "collabora/code:latest";
      ports = [ "127.0.0.1:9980:9980" ];
      environment = {
        aliasgroup1   = "https://${domain}";
        server_name   = "${collaboraDomain}:443";
        extra_params  = "--o:ssl.enable=false --o:ssl.termination=true";
      };
    };

    services.caddy.virtualHosts.${domain} = {
      useACMEHost = "jonrei.de";
      extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString port}
        header Strict-Transport-Security "max-age=31536000"
        request_body {
          max_size 10GB
        }
      '';
    };

    services.caddy.virtualHosts.${collaboraDomain} = {
      useACMEHost = "jonrei.de";
      extraConfig = ''
        reverse_proxy http://127.0.0.1:9980
      '';
    };
  };
}
