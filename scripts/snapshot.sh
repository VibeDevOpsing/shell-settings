#!/usr/bin/env bash
# ==============================================================================
# scripts/snapshot.sh -- save the CURRENT machine state into the repo
#
# Config files are symlinked, so edits to ~/.zshrc etc. already land in the repo.
# This script captures the things that are not files:
#   - Homebrew packages installed since last time -> appended to Brewfile
#     (the curated Brewfile is never rewritten; nothing is removed)
#   - Antigravity IDE extensions -> ide/antigravity-ide/extensions.txt
# Then shows `git status` so you can review and commit.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

cd "$DOTFILES"
load_brew || true

# --- Homebrew -----------------------------------------------------------------
step "Homebrew: looking for packages not yet in Brewfile / Brewfile.apps"
if command -v brew >/dev/null 2>&1; then
  tmp="$(mktemp)"
  HOMEBREW_NO_AUTO_UPDATE=1 brew bundle dump --force --no-vscode --file="$tmp" 2>/dev/null

  # `type "name"` keys already tracked in the repo
  known="$(cat Brewfile Brewfile.apps 2>/dev/null |
    sed -nE 's/^[[:space:]]*#?[[:space:]]*(tap|brew|cask|npm|mas|uv|cargo|go)[[:space:]]+("[^"]+").*/\1 \2/p')"

  added=""
  while IFS= read -r line; do
    key="$(printf '%s\n' "$line" | sed -nE 's/^(tap|brew|cask|npm|mas|uv|cargo|go)[[:space:]]+("[^"]+").*/\1 \2/p')"
    [ -n "$key" ] || continue
    if ! printf '%s\n' "$known" | grep -qxF "$key"; then
      added="${added}${line}"$'\n'
    fi
  done < "$tmp"
  rm -f "$tmp"

  if [ -n "$added" ]; then
    {
      echo
      echo "# --- Added by snapshot.sh on $(date '+%Y-%m-%d') (move into a section above) ---"
      printf '%s' "$added"
    } >> Brewfile
    ok "added new packages to Brewfile:"
    printf '%s' "$added" | sed 's/^/      /'
  else
    ok "Brewfile is up to date"
  fi

  missing="$(HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --file=Brewfile --verbose 2>/dev/null |
    grep -E '^->|^→' || true)"
  if [ -n "$missing" ]; then
    warn "listed in Brewfile but not installed here:"
    printf '%s\n' "$missing" | sed 's/^/      /'
  fi
else
  warn "Homebrew not found, skipping Brewfile snapshot"
fi

# --- IDE extensions -----------------------------------------------------------
step "Antigravity IDE extensions"
cli="$HOME/.antigravity-ide/antigravity-ide/bin/antigravity-ide"
if [ -x "$cli" ]; then
  "$cli" --list-extensions 2>/dev/null | grep -E '^[A-Za-z0-9-]+\.[A-Za-z0-9-]+$' \
    > ide/antigravity-ide/extensions.txt || true
  ok "$(wc -l < ide/antigravity-ide/extensions.txt | tr -d ' ') extensions saved"
else
  warn "Antigravity IDE CLI not found, skipped"
fi

echo
git status --short 2>/dev/null || true
echo
echo "Review, then:  git add -A && git commit -m 'chore: update snapshot' && git push"
