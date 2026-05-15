{ pkgs, ... }:
{
  home.stateVersion = "25.11";

  # Shell
  programs.bash.enable = true;

  # Git
  programs.git = {
    enable = true;
    settings.user = {
      name = "Jonas";
      email = "mail@jonrei.de";
    };
  };

  # Add dotfiles here — they apply to every machine jonas is on.
  # Examples:
  #   programs.zsh.enable = true;
  #   programs.neovim.enable = true;
  #   programs.tmux.enable = true;
}
