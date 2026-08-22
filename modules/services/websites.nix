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
              description = "Full domain name, e.g. example.com.";
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
        name = site.domain;
        value = {
          extraConfig = ''
            root * ${site.root}
            file_server
          '';
        };
      }) cfg.sites
    );
  };
}
