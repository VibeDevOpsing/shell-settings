#!/usr/bin/env bash
# ==============================================================================
# scripts/install-linux.sh
# Linux Bootstrap: Distro detection (Ubuntu/Debian, Arch, Fedora),
# system packages, Homebrew (Linuxbrew), shell plugins, and symlinks.
# Safe to re-run any time (idempotent).
#
# Usage:
#   ./scripts/install-linux.sh               full setup (distro pkgs + Linuxbrew + configs)
#   ./scripts/install-linux.sh --link-only   only (re)create symlinks
#   ./scripts/install-linux.sh --no-pkg      skip native distro package installation
#   ./scripts/install-linux.sh --no-brew     skip Homebrew (Linuxbrew) installation & bundle
#   ./scripts/install-linux.sh --dry-run     preview actions without modifying the system
#   ./scripts/install-linux.sh --check       verify symlinks, tools, and plugins
#   ./scripts/install-linux.sh --help
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

DO_PKG=1
DO_BREW=1
DO_PLUGINS=1
DO_EXTRAS=1
DO_CHECK=0

usage() { sed -n '3,15p' "$0" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --link-only)    DO_PKG=0; DO_BREW=0; DO_PLUGINS=0; DO_EXTRAS=0 ;;
    --no-pkg)       DO_PKG=0 ;;
    --no-brew)      DO_BREW=0 ;;
    --dry-run)      DRY_RUN=1 ;;
    --check|doctor) DO_CHECK=1 ;;
    -h|--help)      usage; exit 0 ;;
    *)              die "unknown option: $1 (see --help)" ;;
  esac
  shift
done

[ "$(uname -s)" = "Linux" ] || die "This script is intended for Linux only. For macOS use ./scripts/install-macos.sh"

if [ "$DO_CHECK" -eq 1 ]; then
  run_doctor
  exit 0
fi

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
      *arch*)            DISTRO_FAMILY="arch" ;;
      *debian*|*ubuntu*) DISTRO_FAMILY="debian" ;;
      *fedora*|*rhel*)   DISTRO_FAMILY="fedora" ;;
      *)
        case "$DISTRO" in
          arch|manjaro|endeavouros|garuda|artix)       DISTRO_FAMILY="arch" ;;
          ubuntu|debian|linuxmint|pop|elementary|kali) DISTRO_FAMILY="debian" ;;
          fedora|rhel|centos|rocky|alma)               DISTRO_FAMILY="fedora" ;;
          *)                                           DISTRO_FAMILY="unknown" ;;
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
# 2. Native System Packages by Distro
# ------------------------------------------------------------------------------
install_arch_packages() {
  step "Installing packages via pacman (Arch Linux)"
  local pkgs=(
    base-devel procps-ng file git zsh bash gawk fzf ripgrep fd eza zoxide
    starship bat git-delta yazi neovim tmux jq curl wget unzip fontconfig
  )
  for opt in ttf-jetbrains-mono-nerd ttf-fira-code-nerd podman podman-compose; do
    if pacman -Si "$opt" >/dev/null 2>&1; then
      pkgs+=("$opt")
    fi
  done

  has_sudo pacman -Syu --needed --noconfirm "${pkgs[@]}"
  ok "pacman packages installed"
}

install_debian_packages() {
  step "Installing packages via apt (Ubuntu / Debian)"
  has_sudo apt-get update -y
  has_sudo apt-get install -y \
    build-essential procps file git zsh bash gawk fzf ripgrep fd-find bat \
    tmux jq neovim curl wget unzip fontconfig ca-certificates

  ok "apt core packages installed"

  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$HOME/.local/bin"
    if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
      ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
      ok "symlinked fdfind -> ~/.local/bin/fd"
    fi
    if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
      ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
      ok "symlinked batcat -> ~/.local/bin/bat"
    fi
  fi

  # Starship prompt
  if ! command -v starship >/dev/null 2>&1; then
    step "Installing Starship prompt"
    if [ "$DRY_RUN" -eq 1 ]; then
      run_cmd "curl -sS https://starship.rs/install.sh | sh -s -- -y"
    else
      curl -sS https://starship.rs/install.sh | sh -s -- -y >/dev/null 2>&1 || warn "could not install starship"
      ok "starship installed"
    fi
  fi

  # Zoxide (smarter cd)
  if ! command -v zoxide >/dev/null 2>&1; then
    step "Installing Zoxide"
    if [ "$DRY_RUN" -eq 1 ]; then
      run_cmd "curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash"
    else
      curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash >/dev/null 2>&1 || warn "could not install zoxide"
      ok "zoxide installed"
    fi
  fi

  # Eza (modern ls)
  if ! command -v eza >/dev/null 2>&1; then
    step "Installing Eza"
    if [ "$DRY_RUN" -eq 1 ]; then
      run_cmd "install eza via apt or official gierens repository"
    elif apt-cache show eza >/dev/null 2>&1; then
      has_sudo apt-get install -y eza
    else
      has_sudo mkdir -p /etc/apt/keyrings
      wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | has_sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null || true
      echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | has_sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null 2>&1 || true
      has_sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list 2>/dev/null || true
      has_sudo apt-get update -y >/dev/null 2>&1 || true
      has_sudo apt-get install -y eza 2>/dev/null || warn "eza install skipped (will install via Homebrew or fall back to ls)"
    fi
  fi
}

install_fedora_packages() {
  step "Installing packages via dnf (Fedora / RHEL)"
  has_sudo dnf install -y \
    @development-tools procps-ng file git zsh bash gawk fzf ripgrep fd-find \
    bat git-delta tmux jq neovim curl wget unzip fontconfig starship zoxide eza
  ok "dnf packages installed"

  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$HOME/.local/bin"
    if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
      ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi
  fi
}

install_nerd_fonts() {
  step "Nerd Fonts (JetBrains Mono)"
  local font_dir="$HOME/.local/share/fonts"
  if command -v fc-list >/dev/null 2>&1 && fc-list : family | grep -qi "JetBrainsMono Nerd Font"; then
    ok "JetBrainsMono Nerd Font already installed"
    return
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    run_cmd "download JetBrainsMono Nerd Font -> $font_dir"
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
        warn "No supported distro package manager found. Falling back to Homebrew (Linuxbrew)."
      fi
      ;;
  esac
  install_nerd_fonts
}

# ------------------------------------------------------------------------------
# Run
# ------------------------------------------------------------------------------
detect_distro

if [ "$DO_PKG" -eq 1 ]; then
  install_system_packages
fi

if [ "$DO_BREW" -eq 1 ]; then
  install_brew
  brew_bundle "$DOTFILES/Brewfile"
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

step "Linux setup complete! Open a new terminal (or run: exec zsh)."
