#!/usr/bin/env bash
# ==============================================================================
# scripts/lib.sh
# Shared functions for macOS and Linux installers (logging, Homebrew/Linuxbrew,
# shell plugins, symlinks, IDE extensions, Neovim plugins, and health checks).
# ==============================================================================

DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)}"
ZSH_PLUGINS="${ZSH_PLUGINS:-$HOME/.zsh/plugins}"
DRY_RUN="${DRY_RUN:-0}"

# --- Output helpers -----------------------------------------------------------
if [ -t 1 ]; then
  C_B=$'\033[1;34m'; C_G=$'\033[1;32m'; C_Y=$'\033[1;33m'; C_R=$'\033[1;31m'; C_0=$'\033[0m'
else
  C_B=; C_G=; C_Y=; C_R=; C_0=
fi

step() { printf '\n%s==>%s %s\n' "$C_B" "$C_0" "$*"; }
ok()   { printf '  %s✓%s %s\n' "$C_G" "$C_0" "$*"; }
warn() { printf '  %s!%s %s\n' "$C_Y" "$C_0" "$*"; }
die()  { printf '%sError:%s %s\n' "$C_R" "$C_0" "$*" >&2; exit 1; }

run_cmd() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  %s[dry-run]%s %s\n' "$C_Y" "$C_0" "$*"
    return 0
  fi
  "$@"
}

# --- Privilege elevation ------------------------------------------------------
has_sudo() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  %s[dry-run]%s sudo %s\n' "$C_Y" "$C_0" "$*"
    return 0
  fi
  if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    warn "neither root nor sudo available; trying without privilege elevation"
    "$@"
  fi
}

# --- Homebrew (macOS & Linuxbrew) ---------------------------------------------
load_brew() {
  local b
  for b in \
    /opt/homebrew/bin/brew \
    /usr/local/bin/brew \
    /home/linuxbrew/.linuxbrew/bin/brew \
    "$HOME/.linuxbrew/bin/brew"
  do
    if [ -x "$b" ]; then
      eval "$("$b" shellenv)"
      return 0
    fi
  done
  return 1
}

install_brew() {
  step "Homebrew"
  if command -v brew >/dev/null 2>&1 || load_brew; then
    ok "already installed ($(brew --prefix))"
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    run_cmd "install Homebrew from https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    return 0
  fi
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_brew || die "Homebrew installed but brew binary was not found in standard paths"
  ok "installed ($(brew --prefix))"
}

brew_bundle() {
  local file="$1"
  step "brew bundle: $(basename "$file")"
  if [ "$DRY_RUN" -eq 1 ]; then
    run_cmd brew bundle --file="$file"
    return 0
  fi
  export HOMEBREW_NO_ENV_HINTS=1
  if [ "$(uname -s)" = "Linux" ]; then
    # On Linux, filter out macOS-only casks, Mac App Store apps, and macOS-specific formulae
    local tmp_brewfile
    tmp_brewfile="$(mktemp)"
    grep -vE '^[[:space:]]*(cask|mas)[[:space:]]|trusted:[[:space:]]*\{[[:space:]]*casks:|"xcodegen"' "$file" > "$tmp_brewfile" || true
    if brew bundle --file="$tmp_brewfile"; then
      ok "done (Linux CLI bundle)"
    else
      warn "some Linuxbrew packages failed - check with: brew bundle check"
    fi
    rm -f "$tmp_brewfile"
  else
    if brew bundle --file="$file"; then
      ok "done"
    else
      warn "some packages failed - re-run later or check: brew bundle check --file=$file"
    fi
  fi
}

# --- Zsh plugins & ble.sh -----------------------------------------------------
clone_or_update() {
  local url="$1" dir="$2"
  if [ "$DRY_RUN" -eq 1 ]; then
    run_cmd "git clone/update $url -> $dir"
    return 0
  fi
  if [ -d "$dir/.git" ]; then
    if git -C "$dir" pull --ff-only --quiet; then
      ok "updated $(basename "$dir")"
    else
      warn "could not update $(basename "$dir")"
    fi
  else
    rm -rf "$dir"
    if git clone --depth 1 --quiet "$url" "$dir"; then
      ok "installed $(basename "$dir")"
    else
      warn "could not clone $(basename "$dir")"
    fi
  fi
}

install_zsh_plugins() {
  step "Zsh plugins -> $ZSH_PLUGINS"
  [ "$DRY_RUN" -eq 1 ] || mkdir -p "$ZSH_PLUGINS"
  clone_or_update https://github.com/zsh-users/zsh-autosuggestions     "$ZSH_PLUGINS/zsh-autosuggestions"
  clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_PLUGINS/zsh-syntax-highlighting"
  clone_or_update https://github.com/zsh-users/zsh-completions         "$ZSH_PLUGINS/zsh-completions"
  clone_or_update https://github.com/Aloxaf/fzf-tab                    "$ZSH_PLUGINS/fzf-tab"
}

install_blesh() {
  step "ble.sh (autosuggestions + highlighting for bash)"
  if [ "$DRY_RUN" -eq 1 ]; then
    run_cmd "clone and build ble.sh -> ~/.local/share/blesh"
    return 0
  fi
  local make_bin gawk_bin tmp
  make_bin="$(command -v gmake || command -v make || true)"
  gawk_bin="$(command -v gawk || true)"
  [ -n "$make_bin" ] || { warn "make not found, skipping ble.sh"; return; }
  [ -n "$gawk_bin" ] || { warn "gawk not found, skipping ble.sh"; return; }
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

# --- Symlinks -----------------------------------------------------------------
link() {
  local src="$DOTFILES/$1" dst="$HOME/$2"
  [ -e "$src" ] || { warn "missing in repo: $1"; return; }
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    ok "$2"
    return
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    run_cmd "ln -s $src $dst"
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
  link config/git/config               .config/git/config
  link config/git/ignore               .config/git/ignore
  link config/yazi/yazi.toml           .config/yazi/yazi.toml

  if [ "$(uname -s)" = "Darwin" ]; then
    link ide/antigravity-ide/settings.json "Library/Application Support/Antigravity IDE/User/settings.json"
  else
    if [ -d "$HOME/.config/Antigravity IDE/User" ] || [ -d "$DOTFILES/ide/antigravity-ide" ]; then
      link ide/antigravity-ide/settings.json ".config/Antigravity IDE/User/settings.json"
    fi
  fi

  [ -d "$BACKUP_DIR" ] && warn "backups saved in $BACKUP_DIR"
  return 0
}

# --- Extras: IDE extensions, Neovim plugins, finalize -------------------------
install_ide_extensions() {
  step "Antigravity IDE extensions"
  local cli="$HOME/.antigravity-ide/antigravity-ide/bin/antigravity-ide" ext
  if [ ! -x "$cli" ]; then
    warn "Antigravity IDE CLI not found - skipping extensions"
    return
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    run_cmd "install extensions from ide/antigravity-ide/extensions.txt"
    return
  fi
  while IFS= read -r ext; do
    case "$ext" in ''|\#*) continue ;; esac
    if "$cli" --install-extension "$ext" >/dev/null 2>&1; then
      ok "$ext"
    else
      warn "failed: $ext"
    fi
  done < "$DOTFILES/ide/antigravity-ide/extensions.txt"
}

install_nvim_plugins() {
  step "Neovim plugins (lazy.nvim, pinned by lazy-lock.json)"
  if ! command -v nvim >/dev/null 2>&1; then
    warn "nvim not found"
    return
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    run_cmd "nvim --headless '+Lazy! restore' +qa"
    return
  fi
  if nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1; then
    ok "done"
  else
    warn "open nvim once to finish plugin install"
  fi
}

finalize() {
  step "Final touches"
  if [ "$DRY_RUN" -eq 1 ]; then
    run_cmd "reset zsh caches, configure default shell, ensure ~/.zshrc.local & ~/.bashrc.local exist"
    return
  fi
  mkdir -p "$HOME/.cache/zsh" "$HOME/.local/bin"
  rm -f "$HOME/.zcompdump"
  ok "caches reset"

  local zsh_path
  zsh_path="$(command -v zsh || true)"
  case "${SHELL:-}" in
    */zsh) ok "default shell is zsh" ;;
    *)
      if [ -n "$zsh_path" ]; then
        if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
          echo "$zsh_path" | has_sudo tee -a /etc/shells >/dev/null 2>&1 || true
        fi
        if grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
          if chsh -s "$zsh_path" 2>/dev/null; then
            ok "default shell -> $zsh_path"
          else
            warn "run 'chsh -s $zsh_path' to set zsh as default shell"
          fi
        fi
      fi
      ;;
  esac

  for f in .zshrc.local .bashrc.local; do
    [ -e "$HOME/$f" ] || { touch "$HOME/$f"; ok "created empty ~/$f (for secrets, not in git)"; }
  done
}

# --- Health check (--check / doctor) ------------------------------------------
run_doctor() {
  step "Checking dotfiles health (--check)"
  local issues=0

  load_brew || true

  # 1. Symlinks
  local pairs=(
    "shell/common.sh:.config/shell/common.sh"
    "shell/zsh/zshrc:.zshrc"
    "shell/bash/bashrc:.bashrc"
    "shell/bash/bash_profile:.bash_profile"
    "shell/bash/inputrc:.inputrc"
    "config/ghostty/config:.config/ghostty/config"
    "config/starship.toml:.config/starship.toml"
    "config/nvim:.config/nvim"
    "config/tmux/tmux.conf:.tmux.conf"
    "config/git/config:.config/git/config"
    "config/git/ignore:.config/git/ignore"
    "config/yazi/yazi.toml:.config/yazi/yazi.toml"
  )
  local pair src dst
  for pair in "${pairs[@]}"; do
    src="$DOTFILES/${pair%%:*}"
    dst="$HOME/${pair#*:}"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
      ok "symlink ~/${pair#*:}"
    else
      warn "missing or mismatched symlink: ~/${pair#*:}"
      issues=$((issues + 1))
    fi
  done

  # 2. Core CLI tools
  local cmd
  for cmd in git zsh bash fzf rg eza zoxide starship nvim tmux jq bat delta yazi; do
    if command -v "$cmd" >/dev/null 2>&1; then
      ok "tool: $cmd ($(command -v "$cmd"))"
    elif [ "$cmd" = "bat" ] && command -v batcat >/dev/null 2>&1; then
      ok "tool: batcat ($(command -v batcat))"
    else
      warn "missing tool: $cmd"
      issues=$((issues + 1))
    fi
  done

  if command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1; then
    ok "tool: fd"
  else
    warn "missing tool: fd"
    issues=$((issues + 1))
  fi

  # 3. Zsh plugins
  local p
  for p in zsh-autosuggestions zsh-syntax-highlighting zsh-completions fzf-tab; do
    if [ -d "$ZSH_PLUGINS/$p" ]; then
      ok "zsh plugin: $p"
    else
      warn "missing zsh plugin: $p"
      issues=$((issues + 1))
    fi
  done

  if [ "$issues" -eq 0 ]; then
    step "All checks passed!"
  else
    step "Health check finished with $issues warning(s). Run ./install.sh to fix."
  fi
  return 0
}
