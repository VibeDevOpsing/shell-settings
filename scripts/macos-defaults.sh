#!/usr/bin/env bash
# ==============================================================================
# scripts/macos-defaults.sh
# Apply sensible macOS system defaults for developers (Keyboard, Finder, Dock).
# Run directly or via: ./install.sh --macos-defaults
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

[ "$(uname -s)" = "Darwin" ] || die "macos-defaults.sh can only be run on macOS"

step "Applying macOS developer defaults"

# Close System Settings to prevent it from overriding changes
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

# --- Keyboard & Input ---------------------------------------------------------
# Fast key repeat rate and short initial delay (ideal for Neovim & terminal)
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# Disable smart quotes, smart dashes, and auto-correct
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
ok "Keyboard: fast key repeat enabled, auto-correct disabled"

# --- Finder -------------------------------------------------------------------
# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true
# Show status bar and path bar
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true
# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# Search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# Disable warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
ok "Finder: hidden files, extensions, path bar, and folder sorting configured"

# --- Dock & Screenshots -------------------------------------------------------
# Save screenshots in PNG format without window shadows
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true
# Speed up Mission Control animations
defaults write com.apple.dock expose-animation-duration -float 0.15
# Don't automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false
ok "Dock & Screenshots configured"

# Restart affected applications
for app in "Finder" "Dock"; do
  killall "$app" >/dev/null 2>&1 || true
done

ok "macOS defaults applied!"
