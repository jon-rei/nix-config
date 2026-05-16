{ pkgs, ... }:
{
  home.stateVersion = "25.11";

  # Shell
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -alh";
      update = "sudo nixos-rebuild switch";
    };
    history.size = 10000;
  };

  # Git
  programs.git = {
    enable = true;
    settings.user = {
      name = "Jonas";
      email = "mail@jonrei.de";
    };
  };
}
