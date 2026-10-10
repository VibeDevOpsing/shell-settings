#!/usr/bin/env bash
# ==============================================================================
# scripts/install-linux.sh
# Linux Bootstrap: Distro detection (Ubuntu/Debian, Arch, Fedora),
# packages, shell plugins, symlinks.
# Safe to re-run any time (idempotent).
#
# Usage:
#   ./scripts/install-linux.sh               full setup (distro packages + configs)
#   ./scripts/install-linux.sh --link-only   only (re)create symlinks
#   ./scripts/install-linux.sh --no-pkg      skip system package installation
#   ./scripts/install-linux.sh --help
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
ZSH_PLUGINS="$HOME/.zsh/plugins"

DO_PKG=1
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

usage() { sed -n '3,12p' "$0" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --link-only) DO_PKG=0; DO_PLUGINS=0; DO_EXTRAS=0 ;;
    --no-pkg)    DO_PKG=0 ;;
    -h|--help)   usage; exit 0 ;;
    *)           die "unknown option: $1 (see --help)" ;;
  esac
  shift
done

[ "$(uname -s)" = "Linux" ] || die "This script is intended for Linux only. For macOS use ./scripts/install-macos.sh"

# ------------------------------------------------------------------------------
# 1. Distro Detection
# ------------------------------------------------------------------------------
DISTRO=""
DISTRO_FAMILY=""

detect_distro() {
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    DISTRO="${ID:-linux}"
    case "${ID_LIKE:-$ID}" in
      *arch*)          DISTRO_FAMILY="arch" ;;
      *debian*|*ubuntu*) DISTRO_FAMILY="debian" ;;
      *fedora*|*rhel*)   DISTRO_FAMILY="fedora" ;;
      *)
        case "$DISTRO" in
          arch|manjaro|endeavouros|garuda|artix) DISTRO_FAMILY="arch" ;;
          ubuntu|debian|linuxmint|pop|elementary|kali) DISTRO_FAMILY="debian" ;;
          fedora|rhel|centos|rocky|alma) DISTRO_FAMILY="fedora" ;;
          *) DISTRO_FAMILY="unknown" ;;
        esac
        ;;
    esac
  else
    DISTRO_FAMILY="unknown"
    DISTRO="unknown"
  fi
  step "Detected Linux distribution: $DISTRO (family: $DISTRO_FAMILY)"
}

# ------------------------------------------------------------------------------
# 2. Package Installation by Distro
# ------------------------------------------------------------------------------
has_sudo() {
  if [ "$EUID" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    warn "neither root nor sudo available; trying without privilege elevation"
    "$@"
  fi
}

install_arch_packages() {
  step "Installing packages via pacman (Arch Linux)"
  local pkgs=(
    base-devel git zsh bash fzf ripgrep fd eza zoxide starship
    neovim tmux jq curl wget unzip fontconfig
  )
  # Optional tools if present in official repos
  for opt in ttf-jetbrains-mono-nerd ttf-fira-code-nerd podman podman-compose; do
    pacman -Si "$opt" >/dev/null 2>&1 && pkgs+=("$opt") || true
  done

  has_sudo pacman -Syu --needed --noconfirm "${pkgs[@]}"
  ok "pacman packages installed"
}

install_debian_packages() {
  step "Installing packages via apt (Ubuntu / Debian)"
  has_sudo apt-get update -y
  has_sudo apt-get install -y \
    build-essential git zsh bash fzf ripgrep fd-find tmux jq neovim \
    curl wget unzip fontconfig ca-certificates

  ok "apt core packages installed"

  # On Debian/Ubuntu fd is installed as fdfind; symlink to ~/.local/bin/fd if missing
  mkdir -p "$HOME/.local/bin"
  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    ok "symlinked fdfind -> ~/.local/bin/fd"
  fi

  # Starship prompt
  if ! command -v starship >/dev/null 2>&1; then
    step "Installing Starship prompt"
    curl -sS https://starship.rs/install.sh | sh -s -- -y >/dev/null 2>&1 || warn "could not install starship"
    ok "starship installed"
  fi

  # Zoxide (smarter cd)
  if ! command -v zoxide >/dev/null 2>&1; then
    step "Installing Zoxide"
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash >/dev/null 2>&1 || warn "could not install zoxide"
    ok "zoxide installed"
  fi

  # Eza (modern ls)
  if ! command -v eza >/dev/null 2>&1; then
    step "Installing Eza"
    if apt-cache show eza >/dev/null 2>&1; then
      has_sudo apt-get install -y eza
    else
      # Install via official gpg repo for Debian/Ubuntu
      has_sudo mkdir -p /etc/apt/keyrings
      wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | has_sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null || true
      echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | has_sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null 2>&1 || true
      has_sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list 2>/dev/null || true
      has_sudo apt-get update -y >/dev/null 2>&1 || true
      has_sudo apt-get install -y eza 2>/dev/null || warn "eza install skipped (falling back to ls in shell)"
    fi
    command -v eza >/dev/null 2>&1 && ok "eza installed" || warn "eza not available"
  fi
}

install_fedora_packages() {
  step "Installing packages via dnf (Fedora / RHEL)"
  has_sudo dnf install -y \
    @development-tools git zsh bash fzf ripgrep fd-find tmux jq neovim \
    curl wget unzip fontconfig starship zoxide eza
  ok "dnf packages installed"

  # Link fd-find to fd if necessary
  mkdir -p "$HOME/.local/bin"
  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi
}

install_nerd_fonts() {
  step "Nerd Fonts (JetBrains Mono)"
  local font_dir="$HOME/.local/share/fonts"
  if fc-list : family | grep -qi "JetBrainsMono Nerd Font"; then
    ok "JetBrainsMono Nerd Font already installed"
    return
  fi
  mkdir -p "$font_dir"
  local tmp
  tmp="$(mktemp -d)"
  if curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" -o "$tmp/font.tar.xz"; then
    tar -xf "$tmp/font.tar.xz" -C "$font_dir/"
    if command -v fc-cache >/dev/null 2>&1; then
      fc-cache -f "$font_dir" >/dev/null 2>&1 || true
    fi
    ok "JetBrainsMono Nerd Font installed to $font_dir"
  else
    warn "could not download Nerd Font (install manually if needed)"
  fi
  rm -rf "$tmp"
}

install_system_packages() {
  case "$DISTRO_FAMILY" in
    arch)   install_arch_packages ;;
    debian) install_debian_packages ;;
    fedora) install_fedora_packages ;;
    *)
      warn "Unknown Linux distro family ($DISTRO). Attempting generic package install..."
      if command -v pacman >/dev/null 2>&1; then
        install_arch_packages
      elif command -v apt-get >/dev/null 2>&1; then
        install_debian_packages
      elif command -v dnf >/dev/null 2>&1; then
        install_fedora_packages
      else
        warn "No supported package manager found. Please install git, zsh, fzf, ripgrep manually."
      fi
      ;;
  esac
  install_nerd_fonts
}

# ------------------------------------------------------------------------------
# 3. Zsh Plugins & ble.sh
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
  [ -n "$make_bin" ] || { warn "make not found, skipping ble.sh"; return; }
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
# 4. Symlinks
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

  # Linux IDE settings location (standard XDG path)
  if [ -d "$HOME/.config/Antigravity IDE/User" ] || [ -d "$DOTFILES/ide/antigravity-ide" ]; then
    link ide/antigravity-ide/settings.json ".config/Antigravity IDE/User/settings.json"
  fi

  [ -d "$BACKUP_DIR" ] && warn "backups saved in $BACKUP_DIR"
  return 0
}

# ------------------------------------------------------------------------------
# 5. Extras: Neovim plugins, default shell, local files
# ------------------------------------------------------------------------------
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
  zsh_path="$(command -v zsh || true)"
  case "${SHELL:-}" in
    */zsh) ok "default shell is zsh" ;;
    *)
      if [ -n "$zsh_path" ]; then
        if grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
          chsh -s "$zsh_path" 2>/dev/null && ok "default shell -> $zsh_path" ||
            warn "run 'chsh -s $zsh_path' to set zsh as default shell"
        fi
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
detect_distro

if [ "$DO_PKG" -eq 1 ]; then
  install_system_packages
fi

if [ "$DO_PLUGINS" -eq 1 ]; then
  install_zsh_plugins
  install_blesh
fi

link_all

if [ "$DO_EXTRAS" -eq 1 ]; then
  install_nvim_plugins
  finalize
fi

step "Linux setup complete! Open a new terminal (or run: exec zsh)."
