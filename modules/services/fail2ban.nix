{ config, lib, ... }:
{
  options.fail2ban.enable = lib.mkEnableOption "fail2ban intrusion prevention";

  config = lib.mkIf config.fail2ban.enable {
    services.fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "1h";
      bantime-increment = {
        enable = true;
        multipliers = "1 2 4 8 16 32 64";
        maxtime = "168h";
      };
      ignoreIP = [ "127.0.0.1/8" "::1" ];
    };
  };
}
