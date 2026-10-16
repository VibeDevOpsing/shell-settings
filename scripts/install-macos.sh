#!/usr/bin/env bash
# ==============================================================================
# scripts/install-macos.sh
# macOS Bootstrap: Xcode CLT, Homebrew, packages, shell plugins, symlinks.
# Safe to re-run any time (idempotent). Compatible with macOS /bin/bash 3.2+.
#
# Usage:
#   ./scripts/install-macos.sh                  full setup (CLI tools + configs)
#   ./scripts/install-macos.sh --apps           also install GUI apps from Brewfile.apps
#   ./scripts/install-macos.sh --macos-defaults apply recommended macOS system settings
#   ./scripts/install-macos.sh --link-only      only (re)create symlinks
#   ./scripts/install-macos.sh --no-brew        skip Homebrew packages
#   ./scripts/install-macos.sh --dry-run        preview actions without modifying files
#   ./scripts/install-macos.sh --check          verify symlinks, tools, and plugins
#   ./scripts/install-macos.sh --help
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

WITH_APPS=0
WITH_DEFAULTS=0
DO_BREW=1
DO_PLUGINS=1
DO_EXTRAS=1
DO_CHECK=0

usage() { sed -n '3,16p' "$0" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --apps)           WITH_APPS=1 ;;
    --macos-defaults) WITH_DEFAULTS=1 ;;
    --link-only)      DO_BREW=0; DO_PLUGINS=0; DO_EXTRAS=0 ;;
    --no-brew)        DO_BREW=0 ;;
    --dry-run)        DRY_RUN=1 ;;
    --check|doctor)   DO_CHECK=1 ;;
    -h|--help)        usage; exit 0 ;;
    *)                die "unknown option: $1 (see --help)" ;;
  esac
  shift
done

[ "$(uname -s)" = "Darwin" ] || die "This script is intended for macOS only. For Linux use ./scripts/install-linux.sh"

if [ "$DO_CHECK" -eq 1 ]; then
  run_doctor
  exit 0
fi

# ------------------------------------------------------------------------------
# 1. Xcode Command Line Tools (git, make, clang)
# ------------------------------------------------------------------------------
install_clt() {
  step "Xcode Command Line Tools"
  if xcode-select -p >/dev/null 2>&1; then
    ok "already installed"
    return
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    run_cmd "xcode-select --install"
    return
  fi
  xcode-select --install || true
  echo "  Finish the installer dialog; waiting..."
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
  ok "installed"
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

if [ "$WITH_DEFAULTS" -eq 1 ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    run_cmd /usr/bin/env bash "$SCRIPT_DIR/macos-defaults.sh"
  else
    /usr/bin/env bash "$SCRIPT_DIR/macos-defaults.sh"
  fi
fi

step "macOS setup complete! Open a new terminal (or run: exec zsh)."
