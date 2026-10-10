#!/usr/bin/env bash
# ==============================================================================
# scripts/install-macos.sh
# macOS Bootstrap: Homebrew, packages, shell plugins, symlinks.
# Safe to re-run any time (idempotent). Compatible with macOS /bin/bash 3.2+.
#
# Usage:
#   ./scripts/install-macos.sh               full setup (CLI tools + configs)
#   ./scripts/install-macos.sh --apps        also install GUI apps from Brewfile.apps
#   ./scripts/install-macos.sh --link-only   only (re)create symlinks
#   ./scripts/install-macos.sh --no-brew     skip Homebrew packages
#   ./scripts/install-macos.sh --help
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
ZSH_PLUGINS="$HOME/.zsh/plugins"

WITH_APPS=0
DO_BREW=1
DO_PLUGINS=1
DO_EXTRAS=1

# --- output helpers -----------------------------------------------------------
if [ -t 1 ]; then
  C_B=$'\033[1;34m'; C_G=$'\033[1;32m'; C_Y=$'\033[1;33m'; C_R=$'\033[1;31m'; C_0=$'\033[0m'
else
  C_B=; C_G=; C_Y=; C_R=; C_0=
fi
step() { printf '\n%s==>%s %s\n' "$C_B" "$C_0" "$*"; }
ok()   { printf '  %s✓%s %s\n' "$C_G" "$C_0" "$*"; }
warn() { printf '  %s!%s %s\n' "$C_Y" "$C_0" "$*"; }
die()  { printf '%sError:%s %s\n' "$C_R" "$C_0" "$*" >&2; exit 1; }

usage() { sed -n '3,13p' "$0" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --apps)      WITH_APPS=1 ;;
    --link-only) DO_BREW=0; DO_PLUGINS=0; DO_EXTRAS=0 ;;
    --no-brew)   DO_BREW=0 ;;
    -h|--help)   usage; exit 0 ;;
    *)           die "unknown option: $1 (see --help)" ;;
  esac
  shift
done

[ "$(uname -s)" = "Darwin" ] || die "This script is intended for macOS only. For Linux use ./scripts/install-linux.sh"

# ------------------------------------------------------------------------------
# 1. Xcode Command Line Tools (git, make, clang)
# ------------------------------------------------------------------------------
install_clt() {
  step "Xcode Command Line Tools"
  if xcode-select -p >/dev/null 2>&1; then
    ok "already installed"
    return
  fi
  xcode-select --install || true
  echo "  Finish the installer dialog; waiting..."
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
  ok "installed"
}

# ------------------------------------------------------------------------------
# 2. Homebrew + Brewfile(s)
# ------------------------------------------------------------------------------
load_brew() {
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$b" ]; then eval "$("$b" shellenv)"; return 0; fi
  done
  return 1
}

install_brew() {
  step "Homebrew"
  if command -v brew >/dev/null 2>&1 || load_brew; then
    ok "already installed ($(brew --prefix))"
  else
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    load_brew || die "Homebrew installed but brew not found"
    ok "installed"
  fi
}

brew_bundle() {
  local file="$1"
  step "brew bundle: $(basename "$file")"
  export HOMEBREW_NO_ENV_HINTS=1
  if brew bundle --file="$file"; then
    ok "done"
  else
    warn "some packages failed - re-run later or check: brew bundle check --file=$file"
  fi
}

# ------------------------------------------------------------------------------
# 3. Zsh plugins & ble.sh (bash autosuggestions)
# ------------------------------------------------------------------------------
clone_or_update() {
  local url="$1" dir="$2"
  if [ -d "$dir/.git" ]; then
    git -C "$dir" pull --ff-only --quiet && ok "updated $(basename "$dir")" ||
      warn "could not update $(basename "$dir")"
  else
    rm -rf "$dir"
    git clone --depth 1 --quiet "$url" "$dir" && ok "installed $(basename "$dir")"
  fi
}

install_zsh_plugins() {
  step "Zsh plugins -> $ZSH_PLUGINS"
  mkdir -p "$ZSH_PLUGINS"
  clone_or_update https://github.com/zsh-users/zsh-autosuggestions     "$ZSH_PLUGINS/zsh-autosuggestions"
  clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_PLUGINS/zsh-syntax-highlighting"
  clone_or_update https://github.com/zsh-users/zsh-completions         "$ZSH_PLUGINS/zsh-completions"
  clone_or_update https://github.com/Aloxaf/fzf-tab                    "$ZSH_PLUGINS/fzf-tab"
}

install_blesh() {
  step "ble.sh (autosuggestions + highlighting for bash)"
  local make_bin tmp
  make_bin="$(command -v gmake || command -v make || true)"
  [ -n "$make_bin" ] || { warn "make not found, skipping"; return; }
  tmp="$(mktemp -d)"
  if git clone --recursive --depth 1 --shallow-submodules --quiet \
       https://github.com/akinomyoga/ble.sh.git "$tmp/ble.sh" &&
     "$make_bin" -s -C "$tmp/ble.sh" install PREFIX="$HOME/.local" >/dev/null; then
    ok "installed to ~/.local/share/blesh"
  else
    warn "ble.sh install failed (bash still works without it)"
  fi
  rm -rf "$tmp"
}

# ------------------------------------------------------------------------------
# 4. Symlinks (existing files are moved to ~/.dotfiles-backup/<timestamp>/)
# ------------------------------------------------------------------------------
link() {
  local src="$DOTFILES/$1" dst="$HOME/$2"
  [ -e "$src" ] || { warn "missing in repo: $1"; return; }
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    ok "$2"
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$2")"
    mv "$dst" "$BACKUP_DIR/$2"
    warn "backed up old ~/$2"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  ok "$2 -> $1"
}

link_all() {
  step "Linking configs into \$HOME"
  link shell/common.sh                 .config/shell/common.sh
  link shell/zsh/zshrc                 .zshrc
  link shell/bash/bashrc               .bashrc
  link shell/bash/bash_profile         .bash_profile
  link shell/bash/inputrc              .inputrc
  link config/ghostty/config           .config/ghostty/config
  link config/starship.toml            .config/starship.toml
  link config/nvim                     .config/nvim
  link config/tmux/tmux.conf           .tmux.conf
  link ide/antigravity-ide/settings.json "Library/Application Support/Antigravity IDE/User/settings.json"
  [ -d "$BACKUP_DIR" ] && warn "backups saved in $BACKUP_DIR"
  return 0
}

# ------------------------------------------------------------------------------
# 5. Extras: IDE extensions, Neovim plugins, default shell, caches
# ------------------------------------------------------------------------------
install_ide_extensions() {
  step "Antigravity IDE extensions"
  local cli="$HOME/.antigravity-ide/antigravity-ide/bin/antigravity-ide" ext
  if [ ! -x "$cli" ]; then
    warn "Antigravity IDE not installed - install it, then re-run ./scripts/install-macos.sh"
    return
  fi
  while IFS= read -r ext; do
    case "$ext" in ''|\#*) continue ;; esac
    "$cli" --install-extension "$ext" >/dev/null 2>&1 && ok "$ext" || warn "failed: $ext"
  done < "$DOTFILES/ide/antigravity-ide/extensions.txt"
}

install_nvim_plugins() {
  step "Neovim plugins (lazy.nvim, pinned by lazy-lock.json)"
  if command -v nvim >/dev/null 2>&1; then
    nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 && ok "done" ||
      warn "open nvim once to finish plugin install"
  else
    warn "nvim not found"
  fi
}

finalize() {
  step "Final touches"
  mkdir -p "$HOME/.cache/zsh" "$HOME/.local/bin"
  rm -f "$HOME/.zcompdump"
  ok "caches reset"

  local zsh_path
  zsh_path="$(command -v zsh)"
  case "$SHELL" in
    */zsh) ok "default shell is zsh" ;;
    *)
      if [ -n "$zsh_path" ]; then
        grep -qx "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
        chsh -s "$zsh_path" && ok "default shell -> $zsh_path"
      fi
      ;;
  esac

  for f in .zshrc.local .bashrc.local; do
    [ -e "$HOME/$f" ] || { touch "$HOME/$f"; ok "created empty ~/$f (for secrets, not in git)"; }
  done
}

# ------------------------------------------------------------------------------
# Run
# ------------------------------------------------------------------------------
printf '%smacOS Bootstrap%s from %s\n' "$C_B" "$C_0" "$DOTFILES"

if [ "$DO_BREW" -eq 1 ]; then
  install_clt
  install_brew
  brew_bundle "$DOTFILES/Brewfile"
  if [ "$WITH_APPS" -eq 1 ]; then
    brew_bundle "$DOTFILES/Brewfile.apps"
  fi
else
  load_brew || true
fi

if [ "$DO_PLUGINS" -eq 1 ]; then
  install_zsh_plugins
  install_blesh
fi

link_all

if [ "$DO_EXTRAS" -eq 1 ]; then
  install_ide_extensions
  install_nvim_plugins
  finalize
fi

step "macOS setup complete! Open a new terminal (or run: exec zsh)."
