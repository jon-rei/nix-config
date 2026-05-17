{ pkgs, ... }:
{
  home.stateVersion = "25.11";

  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "sudo"
          "eza"
          "fzf"
          "zoxide"
        ];
      };
      plugins = [
        {
          name = "fzf-tab";
          src = pkgs.zsh-fzf-tab;
          file = "share/fzf-tab/fzf-tab.plugin.zsh";
        }
        {
          name = "zsh-history-substring-search";
          src = pkgs.zsh-history-substring-search;
          file = "share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh";
        }
      ];
      initContent = ''
        bindkey "^[[1;5C" forward-word
        bindkey "^[[1;5D" backward-word
        bindkey "^[[A" history-substring-search-up
        bindkey "^[[B" history-substring-search-down
      '';
      shellAliases = {
        grep = "rg";
        update = "sudo nixos-rebuild switch";
      };
    };

    fzf = {
      enable = true;
      enableZshIntegration = false;
    };
    zoxide = {
      enable = true;
      enableZshIntegration = false;
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
    };

    git = {
      enable = true;
      settings.user = {
        name = "Jonas";
        email = "mail@jonrei.de";
      };
    };
  };
}
