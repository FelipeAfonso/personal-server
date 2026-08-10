# Sourced by home-manager into .zshrc. History, plugins (autosuggestions,
# syntax highlighting, history-substring-search) are managed by the
# programs.zsh module; everything hand-rolled lives here.

# --- Environment ---
export FZF_DEFAULT_OPTS="--bind ctrl-s:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all"
export ENABLE_INCREMENTAL_TUI=true
export FORCE_COLOR=1

# --- Aliases ---
alias vim="nvim"
alias ls="eza -l"
alias svim="sudo -E -s nvim"

# --- Small functions ---
np() { npm run "$@" }

# Shadow lazygit so the shell follows repo/worktree switches: on exit,
# lazygit writes its final directory to LAZYGIT_NEW_DIR_FILE and we cd
# there. lazygit won't create the parent dir itself, hence the mkdir.
lazygit() {
  export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
  mkdir -p ~/.lazygit
  command lazygit "$@"
  if [ -f "$LAZYGIT_NEW_DIR_FILE" ]; then
    cd "$(cat "$LAZYGIT_NEW_DIR_FILE")" || return
    rm -f "$LAZYGIT_NEW_DIR_FILE" > /dev/null
  fi
}
alias lg="lazygit"

# --- Autoloaded functions ---
fpath=("$HOME/.config/zsh/functions" $fpath)
autoload -Uz codesession multicode create

# --- Vi mode ---
bindkey -v
export KEYTIMEOUT=1

zle-keymap-select() {
  case $KEYMAP in
    vicmd) echo -ne '\e[1 q' ;;
    viins|main) echo -ne '\e[3 q' ;;
  esac
}
zle -N zle-keymap-select

zle-line-init() { echo -ne '\e[3 q' }
zle -N zle-line-init

# --- Tool integrations ---
eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"

# cd=z after zoxide init so the alias points to the real function
alias cd="z"

# --- Highlight colors (static theme, ex-wallust) ---
[[ -f "$HOME/.config/zsh/zsh-colors.sh" ]] && source "$HOME/.config/zsh/zsh-colors.sh"

# --- Prompt ---
eval "$(starship init zsh)"
