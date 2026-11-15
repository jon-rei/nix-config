{
  config,
  lib,
  ...
}:
let
  baseDomain = "jonrei.de";
  domain = "notify.${baseDomain}";
  igotifyDomain = "igotify.${baseDomain}";
  port = 8680;
  igotifyPort = 8681;
in
{
  options.gotify = {
    enable = lib.mkEnableOption "Gotify push notification server with iGotify iOS bridge";

    adminPasswordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        File containing GOTIFY_DEFAULTUSER_PASS=... for the initial gotify admin
        user. Point this at an agenix secret, e.g. secrets/gotify-defaultuser-pass.age.
        Until set, gotify's built-in admin/admin default applies.
      '';
    };
  };

  config = lib.mkIf config.gotify.enable {
    motd.services = [
      "gotify-server"
      "podman-igotify"
    ];

    services.gotify = {
      enable = true;
      environment = {
        GOTIFY_SERVER_PORT = port;
        GOTIFY_REGISTRATION = "false";
      };
      environmentFiles = lib.optional (
        config.gotify.adminPasswordFile != null
      ) config.gotify.adminPasswordFile;
    };

    # iGotify Notification Assistant: relays gotify messages to iOS via APNs/SecNtfy.
    # Only published on localhost; Caddy terminates TLS at igotifyDomain.
    # GOTIFY_URLS/GOTIFY_CLIENT_TOKENS/SECNTFY_TOKENS stay empty because both
    # services are reachable via public domains; the iOS app supplies the tokens.
    virtualisation.podman.enable = true;
    virtualisation.oci-containers.backend = "podman";
    virtualisation.oci-containers.containers.igotify = {
      # renovate: datasource=docker depName=ghcr.io/androidseb25/igotify-notification-assist
      image = "ghcr.io/androidseb25/igotify-notification-assist:latest";
      pull = "newer";
      autoStart = true;
      ports = [ "127.0.0.1:${toString igotifyPort}:8080" ];
      volumes = [ "igotify-data:/app/data" ];
    };

    services.caddy.virtualHosts.${domain} = {
      useACMEHost = baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString port}
      '';
    };

    services.caddy.virtualHosts.${igotifyDomain} = {
      useACMEHost = baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString igotifyPort}
      '';
    };

    backup.paths = lib.mkIf config.backup.enable [
      "/var/lib/${config.services.gotify.stateDirectoryName}"
    ];
  };
}
