# ==============================================================================
# Brewfile — CLI tools, fonts & terminals (installed by ./install.sh)
#   brew bundle --file=Brewfile            # install
#   brew bundle check --file=Brewfile      # what's missing
#   ./scripts/snapshot.sh                  # re-generate from current machine
# ==============================================================================

tap "devnullvoid/pvetui"
tap "jebi-sh/tap", trusted: { casks: ["jebi"] }
tap "ngrok/ngrok", trusted: { casks: ["ngrok"] }
tap "oven-sh/bun"

# --- Shell core (required by the zsh/bash config) -----------------------------
brew "git"
brew "zsh"
brew "bash"                 # bash 5 (macOS ships 3.2)
brew "bash-completion@2"
brew "gawk"                 # used by ble.sh
brew "make"                 # gmake, used to build ble.sh
brew "fzf"
brew "fd"
brew "ripgrep"
brew "eza"
brew "zoxide"
brew "starship"
brew "neovim"
brew "tmux"
brew "jq"

# --- Languages & runtimes -----------------------------------------------------
brew "node"
brew "oven-sh/bun/bun"
brew "python@3.12"
brew "uv"

# --- Containers ---------------------------------------------------------------
brew "podman"
brew "podman-compose"
brew "docker-compose"

# --- Dev / network tools ------------------------------------------------------
brew "gh"
brew "cloudflared"
brew "mkcert"
brew "xcodegen"
brew "speedtest-cli"

# --- AI CLIs ------------------------------------------------------------------
brew "gemini-cli"
brew "block-goose-cli"

# --- File managers & TUI ------------------------------------------------------
brew "ranger"
brew "yazi"
brew "ncdu"
brew "tuios"

# --- Media & documents --------------------------------------------------------
brew "ffmpeg", link: false
brew "ffmpeg-full", link: true
brew "whisper.cpp"
brew "imagemagick-full", link: true
brew "poppler"
brew "resvg"
brew "sevenzip"
brew "yt-dlp"

# --- Terminals & fonts --------------------------------------------------------
cask "ghostty"
cask "warp"
cask "font-fira-code-nerd-font"
cask "font-jetbrains-mono-nerd-font"
cask "font-symbols-only-nerd-font"

# --- Utilities ----------------------------------------------------------------
cask "angry-ip-scanner"
cask "handy"
cask "ngrok"
cask "devnullvoid/pvetui/pvetui", trusted: true

# --- Global npm packages ------------------------------------------------------
npm "antigravity-telegram-remote"
