{ config, lib, pkgs, ... }:
let
  services = config.motd.services;

  serviceScript = pkgs.writeShellScript "motd-services" (
    lib.concatMapStrings (svc: ''
      _st=$(systemctl is-active ${lib.escapeShellArg svc} 2>/dev/null)
      case "$_st" in
        active)  printf '\033[32m●\033[0m %s  ' ${lib.escapeShellArg svc} ;;
        failed)  printf '\033[31m●\033[0m %s [failed]  ' ${lib.escapeShellArg svc} ;;
        *)       printf '\033[33m●\033[0m %s [%s]  ' ${lib.escapeShellArg svc} "$_st" ;;
      esac
    '') services
  );

  fastfetchConfig = {
    logo.type = "none";
    modules = [
      "title"
      "separator"
      "os"
      "kernel"
      "uptime"
      "cpu"
      "memory"
      { type = "disk";    key = "Disk";    folders = "/"; }
      { type = "localip"; showIpv4 = true; showIpv6 = false; compact = true; }
    ] ++ lib.optional (services != []) {
      type = "command";
      key  = "Services";
      text = toString serviceScript;
    };
  };
in
{
  options.motd = {
    enable   = lib.mkEnableOption "fastfetch MOTD on SSH login";
    services = lib.mkOption {
      type        = lib.types.listOf lib.types.str;
      default     = [];
      description = "Systemd units to show status for. Each service module appends itself here.";
    };
  };

  config = lib.mkIf config.motd.enable {
    environment.systemPackages = [ pkgs.fastfetch ];

    environment.etc."fastfetch/config.jsonc".text =
      builtins.toJSON fastfetchConfig;

    programs.zsh.loginShellInit = ''
      ${pkgs.fastfetch}/bin/fastfetch --config /etc/fastfetch/config.jsonc
    '';
  };
}
