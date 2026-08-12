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

      run-shell ${pkgs.vimPlugins.tmux-nvim}/tmux.nvim.tmux
    '';
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "Felipe Afonso";
      user.email = "fmunhozafonso@gmail.com";
      init.defaultBranch = "main";
      # Config is read-only under home-manager, so `gh auth setup-git`
      # can't write this itself; needed for https pushes on headless rlyeh.
      credential."https://github.com".helper = "!gh auth git-credential";
    };
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
    # Global agent prompts: the shared desktop prompt (also tracked in the
    # personal-desktop repo as agents/*.md — keep both in sync by hand) plus
    # rlyeh-specific operating notes.
    ".claude/CLAUDE.md".text =
      builtins.readFile ./agents/claude-global.md
      + "\n"
      + builtins.readFile ./agents/rlyeh-agents.md;
    ".codex/AGENTS.md".text =
      builtins.readFile ./agents/codex-global.md
      + "\n"
      + builtins.readFile ./agents/rlyeh-agents.md;
  };
}
