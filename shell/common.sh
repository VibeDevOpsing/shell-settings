# shellcheck shell=sh
# ==============================================================================
# SHARED SHELL CONFIG (sourced by both ~/.zshrc and ~/.bashrc)
# Location: ~/.config/shell/common.sh  ->  symlink into the config-settings repo
# Keep this file POSIX-compatible: no zsh/bash-only syntax here.
# ==============================================================================

# ------------------------------------------------------------------------------
# Repo location (resolved from the symlink created by install.sh)
# ------------------------------------------------------------------------------
_dot_link=$(readlink "$HOME/.config/shell/common.sh" 2>/dev/null)
if [ -n "$_dot_link" ]; then
  DOTFILES="${_dot_link%/shell/common.sh}"
  export DOTFILES
fi
unset _dot_link

# Homebrew (Apple Silicon, Intel Mac, or Linuxbrew)
# ------------------------------------------------------------------------------
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# ------------------------------------------------------------------------------
# PATH (idempotent: re-sourcing does not create duplicates)
# ------------------------------------------------------------------------------
path_prepend() { case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH" ;; esac; }
path_append()  { case ":$PATH:" in *":$1:"*) ;; *) PATH="$PATH:$1" ;; esac; }

export BUN_INSTALL="$HOME/.bun"
path_prepend "$BUN_INSTALL/bin"
path_prepend "$HOME/.antigravity-ide/antigravity-ide/bin"
path_prepend "$HOME/.local/bin"
path_append  "$HOME/.lmstudio/bin"
export PATH

# ------------------------------------------------------------------------------
# Environment
# ------------------------------------------------------------------------------
export EDITOR="nvim"
export VISUAL="nvim"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Podman as Docker backend
if [ -S "$HOME/.local/share/containers/podman/machine/qemu/podman.sock" ] ||
   [ -f "$HOME/.local/share/containers/podman/machine/qemu/podman.sock" ]; then
  export DOCKER_HOST="unix://$HOME/.local/share/containers/podman/machine/qemu/podman.sock"
fi

# ------------------------------------------------------------------------------
# FZF defaults (used by Ctrl+R / Ctrl+T / Alt+C in both shells and by fzf-tab)
# ------------------------------------------------------------------------------
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border --info=inline"
export FZF_CTRL_R_OPTS="--prompt='history> ' \
  --preview 'echo {2..}' --preview-window=down:3:wrap:hidden \
  --bind 'ctrl-/:toggle-preview' \
  --header 'Enter: insert  |  Ctrl-/: preview  |  Esc: cancel'"
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  alias fd="fdfind"
fi
_fd_bin=""
command -v fd >/dev/null 2>&1 && _fd_bin="fd"
[ -z "$_fd_bin" ] && command -v fdfind >/dev/null 2>&1 && _fd_bin="fdfind"
if [ -n "$_fd_bin" ]; then
  export FZF_DEFAULT_COMMAND="$_fd_bin --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="$_fd_bin --type d --hidden --follow --exclude .git"
fi
unset _fd_bin

# ------------------------------------------------------------------------------
# Aliases
# ------------------------------------------------------------------------------
if command -v eza >/dev/null 2>&1; then
  alias l="ll"
  alias ls="eza --icons=always --color=always --group-directories-first"
  alias ll="eza -la --icons=always --color=always --group-directories-first"
  alias la="eza -a --icons=always --color=always --group-directories-first"
  alias tree="eza --tree --icons=always"
fi

alias c="clear"
alias h="history"
alias v="nvim"
alias vim="nvim"
alias vi="nvim"
alias docker="podman"
alias ghosttyconfig="nvim ~/.config/ghostty/config"
alias nvimconfig="nvim ~/.config/nvim/init.lua"
alias dotfiles='cd "$DOTFILES"'
