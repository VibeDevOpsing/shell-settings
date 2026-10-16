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
elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then
  eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
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

# Bat (syntax-highlighted cat & man pager) and Delta (git pager)
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
  alias bat="batcat"
fi
if command -v bat >/dev/null 2>&1; then
  export BAT_THEME="tokyonight_night"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi
if command -v delta >/dev/null 2>&1; then
  export GIT_PAGER="delta"
fi

# Podman as Docker backend (supports generic symlink, applehv, qemu, and Linux rootless)
if [ -z "${DOCKER_HOST:-}" ]; then
  for _sock in \
    "$HOME/.local/share/containers/podman/machine/podman.sock" \
    "$HOME/.local/share/containers/podman/machine/applehv/podman.sock" \
    "$HOME/.local/share/containers/podman/machine/qemu/podman.sock" \
    "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"
  do
    if [ -S "$_sock" ] || [ -f "$_sock" ]; then
      export DOCKER_HOST="unix://$_sock"
      break
    fi
  done
  unset _sock
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

if command -v bat >/dev/null 2>&1; then
  export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {} 2>/dev/null'"
fi

# ------------------------------------------------------------------------------
# Aliases & Helper Functions
# ------------------------------------------------------------------------------
if command -v eza >/dev/null 2>&1; then
  alias l="ll"
  alias ls="eza --icons=always --color=always --group-directories-first"
  alias ll="eza -la --icons=always --color=always --group-directories-first"
  alias la="eza -a --icons=always --color=always --group-directories-first"
  alias tree="eza --tree --icons=always"
fi

# Only alias docker to podman when native docker CLI is not installed
if ! command -v docker >/dev/null 2>&1 && command -v podman >/dev/null 2>&1; then
  alias docker="podman"
fi

alias c="clear"
alias h="history"
alias v="nvim"
alias vim="nvim"
alias vi="nvim"
alias ghosttyconfig="nvim ~/.config/ghostty/config"
alias nvimconfig="nvim ~/.config/nvim/init.lua"
alias tmuxconfig="nvim ~/.tmux.conf"
alias dotfiles='cd "$DOTFILES"'

# Yazi wrapper: launch with `y` and change into the last visited directory on exit
if command -v yazi >/dev/null 2>&1; then
  y() {
    _yazi_tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$_yazi_tmp"
    if [ -f "$_yazi_tmp" ]; then
      _yazi_cwd="$(cat -- "$_yazi_tmp")"
      if [ -n "$_yazi_cwd" ] && [ "$_yazi_cwd" != "$PWD" ] && [ -d "$_yazi_cwd" ]; then
        cd -- "$_yazi_cwd" || return
      fi
      rm -f -- "$_yazi_tmp"
    fi
    unset _yazi_tmp _yazi_cwd
  }
fi
