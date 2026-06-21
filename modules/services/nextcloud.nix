{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  domain = "cloud.jonrei.de";
  port = 9300;
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
      package = pkgs.nextcloud33;
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
          tasks
          ;
      };
      settings = {
        overwriteprotocol = "https";
        default_phone_region = "DE";
        trusted_domains = [ domain ];
        trusted_proxies = [ "127.0.0.1" ];
        log_type = "file";
        log_rotate_size = 100 * 1024 * 1024;
        loglevel = 2;
        maintenance_window_start = 4;
        "token_auth_enforced" = true;
        "auth.bruteforce.protection.enabled" = true;
        server_id = "drogon";
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
      useACMEHost = "jonrei.de";
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
  };
}
