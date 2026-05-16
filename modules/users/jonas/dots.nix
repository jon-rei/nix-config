{ pkgs, ... }:
{
  home.stateVersion = "25.11";

  # Shell
  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      zplug = {
        enable = true;
        plugins = [
          { name = "zsh-users/zsh-autosuggestions"; }
          { name = "zsh-users/zsh-syntax-highlighting"; }
          { name = "zsh-users/zsh-completions"; }
          { name = "zsh-users/zsh-history-substring-search"; }
          { name = "Aloxaf/fzf-tab"; }
        ];
      };
      initContent = ''
        bindkey "^[[1;5C" forward-word
        bindkey "^[[1;5D" backward-word
      '';

      shellAliases = {
        ll = "ls -alh";
        update = "sudo nixos-rebuild switch";
      };
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
    };

    # Git
    git = {
      enable = true;
      settings.user = {
        name = "Jonas";
        email = "mail@jonrei.de";
      };
    };
  };
}
