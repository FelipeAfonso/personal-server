{ pkgs, ... }:

{
  home.username = "felipe";
  home.homeDirectory = "/home/felipe";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    neovim # config below manages its own plugins via vim.pack (needs >= 0.12)
    eza
    fzf
    zoxide
    yazi
    starship
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "less";
    BUN_INSTALL = "$HOME/.bun";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/go/bin"
    "$HOME/.cargo/bin"
    "$HOME/.bun/bin"
  ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;
    history = {
      size = 10000;
      save = 10000;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
    };
    initContent = builtins.readFile ./zsh/init.zsh;
  };

  programs.tmux = {
    enable = true;
    extraConfig = builtins.readFile ./tmux/tmux.conf + ''

      run-shell ${pkgs.tmuxPlugins.tmux-nvim.rtp}
    '';
  };

  programs.git = {
    enable = true;
    userName = "Felipe Afonso";
    userEmail = "fmunhozafonso@gmail.com";
    extraConfig.init.defaultBranch = "main";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  services.ssh-agent.enable = true;

  xdg.configFile = {
    "nvim" = {
      source = ./nvim;
      recursive = true;
    };
    "zsh/functions" = {
      source = ./zsh/functions;
      recursive = true;
    };
    "zsh/zsh-colors.sh".source = ./zsh/zsh-colors.sh;
    "starship.toml".source = ./starship/starship.toml;
    "lazygit/config.yml".source = ./lazygit/config.yml;
    "tmux/tmux-colors.conf".source = ./tmux/tmux-colors.conf;
    "opencode/opencode.json".source = ./opencode/opencode.json;
    "opencode/tui.json".source = ./opencode/tui.json;
    "opencode/themes" = {
      source = ./opencode/themes;
      recursive = true;
    };
  };

  home.file = {
    ".local/bin/review" = {
      source = ./bin/review;
      executable = true;
    };
    ".local/bin/unreview" = {
      source = ./bin/unreview;
      executable = true;
    };
  };
}
