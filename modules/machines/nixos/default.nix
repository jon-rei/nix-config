{ inputs, nixpkgs }:
let
  mkNixos =
    {
      hostname,
      system ? "x86_64-linux",
    }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs;
        pkgs-unstable = import inputs.nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };
      modules = [
        inputs.agenix.nixosModules.default
        inputs.home-manager.nixosModules.home-manager
        inputs.disko.nixosModules.disko
        ../../services/backup.nix
        ../../services/caddy.nix
        ../../services/fail2ban.nix
        ../../services/motd.nix
        ../../services/opencloud.nix
        ./_common
        ../../users/jonas
        ./${hostname}/configuration.nix
      ];
    };

  hosts = builtins.filter (
    name:
    name != "_common"
    && name != "default.nix"
    && builtins.pathExists (./. + "/${name}/configuration.nix")
  ) (builtins.attrNames (builtins.readDir ./.));
in
builtins.listToAttrs (
  map (hostname: {
    name = hostname;
    value = mkNixos { inherit hostname; };
  }) hosts
)
