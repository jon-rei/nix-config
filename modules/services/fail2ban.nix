{ config, lib, ... }:
{
  options.fail2ban.enable = lib.mkEnableOption "fail2ban intrusion prevention";

  config = lib.mkIf config.fail2ban.enable {
    motd.services = [ "fail2ban" ];
    services.fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "1h";
      bantime-increment = {
        enable = true;
        multipliers = "1 2 4 8 16 32 64";
        maxtime = "168h";
      };
      ignoreIP = [
        "127.0.0.1/8"
        "::1"
      ];
      jails = {
        caddy-auth = {
          settings = {
            enabled = true;
            filter = "caddy-auth";
            backend = "systemd";
            journalmatch = "_SYSTEMD_UNIT=caddy.service";
            maxretry = 5;
            bantime = "1h";
            findtime = "10m";
          };
        };
        caddy-botscan = {
          settings = {
            enabled = true;
            filter = "caddy-botscan";
            backend = "systemd";
            journalmatch = "_SYSTEMD_UNIT=caddy.service";
            maxretry = 20;
            bantime = "24h";
            findtime = "5m";
          };
        };
      };
    };

    environment.etc = {
      "fail2ban/filter.d/caddy-auth.conf".text = ''
        [Definition]
        failregex = .*"remote_ip":"<HOST>".*"status":40[13]
        ignoreregex =
      '';
      "fail2ban/filter.d/caddy-botscan.conf".text = ''
        [Definition]
        failregex = .*"remote_ip":"<HOST>".*"status":4\d\d
        ignoreregex =
      '';
    };
  };
}
