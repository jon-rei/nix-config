{ config, lib, ... }:
{
  options.caddy.enable = lib.mkEnableOption "Caddy web server";

  config = lib.mkIf config.caddy.enable {
    services.caddy.enable = true;
  };
}
