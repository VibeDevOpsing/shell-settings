#!/usr/bin/env bash
# ==============================================================================
# config-settings / install.sh
# Universal Dotfiles Installer (macOS, Ubuntu/Debian, Arch Linux, Fedora)
#
# Automatically detects your operating system and distribution, then runs
# the corresponding optimized setup script:
#   - macOS        -> ./scripts/install-macos.sh
#   - Linux (all)  -> ./scripts/install-linux.sh
#
# Usage:
#   ./install.sh                  Automatic full installation
#   ./install.sh --apps           Install GUI applications (macOS Brewfile.apps)
#   ./install.sh --macos-defaults Apply recommended macOS system preferences
#   ./install.sh --link-only      Only link dotfiles without installing packages
#   ./install.sh --no-brew        Skip Homebrew / Linuxbrew installation & bundle
#   ./install.sh --no-pkg         Linux: skip native distro package manager
#   ./install.sh --dry-run        Preview actions without modifying the system
#   ./install.sh --check          Verify symlinks, tools, and plugins health
#   ./install.sh --macos          Force run macOS installer
#   ./install.sh --linux          Force run Linux installer
#   ./install.sh --help
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
if [ -t 1 ]; then
  C_B=$'\033[1;34m'; C_G=$'\033[1;32m'; C_R=$'\033[1;31m'; C_0=$'\033[0m'
else
  C_B=; C_G=; C_R=; C_0=
fi

usage() { sed -n '3,22p' "$0" | sed 's/^# \{0,1\}//'; }

TARGET_OS=""
FORWARD_ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --macos)   TARGET_OS="macos" ;;
    --linux)   TARGET_OS="linux" ;;
    -h|--help) usage; exit 0 ;;
    *)         FORWARD_ARGS+=("$1") ;;
  esac
  shift
done

# Detect OS if not explicitly set
if [ -z "$TARGET_OS" ]; then
  case "$(uname -s)" in
    Darwin) TARGET_OS="macos" ;;
    Linux)  TARGET_OS="linux" ;;
    *)
      printf '%sError:%s Unsupported OS "%s". Use --macos or --linux.\n' "$C_R" "$C_0" "$(uname -s)" >&2
      exit 1
      ;;
  esac
fi

printf '\n%s==>%s Starting dotfiles installation for %s%s%s...\n' \
  "$C_B" "$C_0" "$C_G" "$TARGET_OS" "$C_0"

case "$TARGET_OS" in
  macos)
    exec /usr/bin/env bash "$SCRIPT_DIR/scripts/install-macos.sh" "${FORWARD_ARGS[@]+"${FORWARD_ARGS[@]}"}"
    ;;
  linux)
    exec /usr/bin/env bash "$SCRIPT_DIR/scripts/install-linux.sh" "${FORWARD_ARGS[@]+"${FORWARD_ARGS[@]}"}"
    ;;
esac
