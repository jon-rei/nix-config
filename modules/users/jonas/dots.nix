{ pkgs, ... }:
{
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    fd
    bat
  ];

  programs = {
    fish = {
      enable = true;
      interactiveShellInit = "set -g fish_greeting";
      shellAliases = {
        grep = "rg";
        update = ''sudo nixos-rebuild switch --flake "git+https://github.com/jon-rei/nix-config#(hostname)" --refresh'';
        ls = "eza";
        ll = "eza -l";
        la = "eza -la";
        lt = "eza --tree";
      };
      plugins = [
        {
          name = "fzf-fish";
          src = pkgs.fishPlugins.fzf-fish.src;
        }
      ];
    };

    starship = {
      enable = true;
      enableFishIntegration = true;
    };

    fzf = {
      enable = true;
      enableFishIntegration = false;
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    direnv.enable = true;

    git = {
      enable = true;
      settings.user = {
        name = "Jonas";
        email = "mail@jonrei.de";
      };
    };
  };
}
