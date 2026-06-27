{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.websites;
in
{
  options.websites = {
    enable = lib.mkEnableOption "static website hosting";

    deployKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "SSH public keys allowed to rsync site content.";
    };

    sites = lib.mkOption {
      default = [ ];
      description = "List of websites to serve.";
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            domain = lib.mkOption {
              type = lib.types.str;
              description = "Full domain name, e.g. example.jonrei.de.";
            };
            acmeHost = lib.mkOption {
              type = lib.types.str;
              description = "Base domain to use the ACME cert from, e.g. jonrei.de.";
            };
            root = lib.mkOption {
              type = lib.types.str;
              description = "Absolute path to the directory Caddy should serve.";
            };
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.deploy = {
      isSystemUser = true;
      group = "deploy";
      shell = pkgs.bash;
      home = "/var/www";
      createHome = true;
      openssh.authorizedKeys.keys = cfg.deployKeys;
    };
    users.groups.deploy = { };

    users.users.caddy.extraGroups = [ "deploy" ];

    services.caddy.virtualHosts = builtins.listToAttrs (
      map (site: {
        name = "https://${site.domain}";
        value = {
          useACMEHost = site.acmeHost;
          extraConfig = ''
            root * ${site.root}
            file_server
          '';
        };
      }) cfg.sites
    );
  };
}
