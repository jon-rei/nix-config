{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  baseDomain = "jonrei.de";
  domain = "cloud.${baseDomain}";
  port = 9300;
  collaboraDomain = "office.${baseDomain}";
  collaboraPort = 9980;
  collaboraSubnet = "10.88.0.0/16";
in
{
  options.nextcloud.enable = lib.mkEnableOption "Nextcloud";

  config = lib.mkIf config.nextcloud.enable {
    motd.services = [ "phpfpm-nextcloud" ];

    age.secrets.nextcloudAdminPassword = {
      file = "${inputs.self}/secrets/nextcloud-admin-password.age";
      owner = "nextcloud";
    };

    services.nginx.virtualHosts."nix-nextcloud".listen = [
      {
        addr = "127.0.0.1";
        port = port;
      }
    ];

    services.nextcloud = {
      enable = true;
      hostName = "nix-nextcloud";
      package = pkgs.nextcloud34;
      database.createLocally = true;
      configureRedis = true;
      maxUploadSize = "16G";
      https = true;
      autoUpdateApps.enable = true;
      extraAppsEnable = true;
      extraApps = with config.services.nextcloud.package.packages.apps; {
        inherit
          calendar
          contacts
          notes
          richdocuments
          previewgenerator
          twofactor_webauthn
          ;
      };
      notify_push = {
        enable = true;
        # Custom url needed here since we use caddy in front of nginx
        nextcloudUrl = "https://${domain}";
      };
      settings = {
        overwriteprotocol = "https";
        "overwrite.cli.url" = "https://${domain}";
        defaultapp = "files";
        default_language = "de";
        default_phone_region = "DE";
        trusted_domains = [ domain ];
        trusted_proxies = [ "127.0.0.1" ];
        log_type = "file";
        log_rotate_size = 100 * 1024 * 1024;
        loglevel = 2;
        maintenance_window_start = 4;
        token_auth_enforced = true;
        "auth.bruteforce.protection.enabled" = true;
        serverid = 1;
      };
      phpOptions."opcache.interned_strings_buffer" = "16";
      config = {
        dbtype = "pgsql";
        adminuser = "admin";
        adminpassFile = config.age.secrets.nextcloudAdminPassword.path;
      };
    };

    systemd.tmpfiles.rules = [
      "f ${config.services.nextcloud.datadir}/nextcloud.log 0640 nextcloud nextcloud -"
    ];

    # notify_push's self-test round-trips through Caddy+nginx, which overwrite
    # X-Forwarded-For on each hop; bypass the proxy chain for the daemon's own
    # calls back to Nextcloud so trusted-proxy validation only sees one hop.
    systemd.services.nextcloud-notify_push.environment.NEXTCLOUD_URL =
      lib.mkForce "http://127.0.0.1:${toString port}";

    services.postgresqlBackup = {
      enable = true;
      databases = [ "nextcloud" ];
      startAt = "*-*-* 03:00:00";
    };

    backup.paths = lib.mkIf config.backup.enable [
      config.services.nextcloud.home
      config.services.postgresqlBackup.location
    ];

    systemd.services."restic-backups-storagebox" = lib.mkIf config.backup.enable {
      after = [ "postgresqlBackup-nextcloud.service" ];
      wants = [ "postgresqlBackup-nextcloud.service" ];
    };

    services.fail2ban.jails.nextcloud = {
      settings = {
        enabled = true;
        filter = "nextcloud";
        backend = "auto";
        logpath = "${config.services.nextcloud.datadir}/nextcloud.log";
        maxretry = 5;
        bantime = "1h";
        findtime = "10m";
      };
    };

    environment.etc."fail2ban/filter.d/nextcloud.conf".text = ''
      [Definition]
      failregex = ^\{.*"remoteAddr":"<HOST>".*"message":"Login failed.*$
      ignoreregex =
    '';

    virtualisation.podman.enable = true;
    virtualisation.podman.defaultNetwork.settings.subnets = [
      {
        subnet = collaboraSubnet;
        gateway = "10.88.0.1";
      }
    ];
    virtualisation.oci-containers.backend = "podman";
    virtualisation.oci-containers.containers.collabora = {
      # renovate: datasource=docker depName=collabora/code
      image = "collabora/code:26.04.3.1.1";
      ports = [ "127.0.0.1:${toString collaboraPort}:${toString collaboraPort}" ];
      environment = {
        aliasgroup1 = "https://${domain}";
        server_name = "${collaboraDomain}:443";
        extra_params = "--o:ssl.enable=false --o:ssl.termination=true --o:welcome.enable=false";
      };
    };

    systemd.services.nextcloud-richdocuments-config = {
      description = "Configure Nextcloud Richdocuments WOPI settings";
      after = [
        "nextcloud-setup.service"
        "podman-collabora.service"
      ];
      requires = [
        "nextcloud-setup.service"
        "podman-collabora.service"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "nextcloud";
        ExecStart =
          let
            occ = "${config.services.nextcloud.occ}/bin/nextcloud-occ";
          in
          pkgs.writeShellScript "nextcloud-richdocuments-config" ''
            set -e
            # Wait for Nextcloud finishing its own upgrade/maintenance-mode
            for i in $(seq 1 60); do
              if ${occ} status --exit-code >/dev/null 2>&1; then
                break
              fi
              echo "Waiting for Nextcloud to leave maintenance mode... ($i/60)"
              sleep 5
            done

            ${occ} config:app:set richdocuments wopi_url --value="http://127.0.0.1:${toString collaboraPort}"
            ${occ} config:app:set richdocuments public_wopi_url --value="https://${collaboraDomain}/"
            ${occ} config:app:set richdocuments wopi_allowlist --value="127.0.0.1,::1,${collaboraSubnet}"
            ${occ} richdocuments:setup
          '';
        RemainAfterExit = true;
      };
    };

    systemd.services.nextcloud-disable-app-api = {
      description = "Disable Nextcloud AppAPI app";
      after = [ "nextcloud-setup.service" ];
      requires = [ "nextcloud-setup.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "nextcloud";
        ExecStart = "${config.services.nextcloud.occ}/bin/nextcloud-occ app:disable app_api";
        RemainAfterExit = true;
      };
    };

    systemd.services.nextcloud-mimetype-migration = {
      description = "Nextcloud mimetype migration";
      after = [ "nextcloud-setup.service" ];
      requires = [ "nextcloud-setup.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "nextcloud";
        ExecStart = "${config.services.nextcloud.occ}/bin/nextcloud-occ maintenance:repair --include-expensive";
        RemainAfterExit = true;
      };
    };

    services.caddy.virtualHosts.${domain} = {
      useACMEHost = baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString port}
        header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        header X-Content-Type-Options "nosniff"
        header X-Frame-Options "SAMEORIGIN"
        header Referrer-Policy "no-referrer"
        request_body {
          max_size 16GB
        }
      '';
    };

    services.caddy.virtualHosts.${collaboraDomain} = {
      useACMEHost = baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString collaboraPort}
      '';
    };
  };
}
