# ⚙️ Config & Settings (macOS Dotfiles)

A universal, modular, and portable repository of workstation configurations for macOS:
**Zsh, Bash, Ghostty, Neovim, Starship, Tmux, Antigravity IDE, Homebrew**.

All configurations are linked via **symbolic links (symlinks)**: any edits to the config files are immediately reflected in this repository.

---

## 📁 Repository Structure

```text
config-settings/
├── Brewfile                     # CLI utilities, languages, fonts, terminals
├── Brewfile.apps                # GUI applications (Chrome, Telegram, Discord...)
├── install.sh                   # Automated setup script for a fresh Mac
├── README.md                    # This guide
├── .gitignore                   # Ignores system junk and local secrets
├── config/
│   ├── ghostty/config           # Ghostty terminal config (TokyoNight, splits, AI scrollback)
│   ├── nvim/                    # Full Neovim config (init.lua + lazy-lock.json)
│   ├── starship.toml            # Optimized shell prompt
│   └── tmux/tmux.conf           # Tmux multiplexer config
├── ide/
│   └── antigravity-ide/         # Antigravity IDE settings and extension list
│       ├── settings.json
│       └── extensions.txt
├── scripts/
│   └── snapshot.sh              # Captures newly installed Homebrew packages and IDE extensions
└── shell/
    ├── common.sh                # SHARED by Zsh and Bash (PATH, variables, aliases, FZF)
    ├── bash/                    # Bash environment (bashrc, bash_profile, inputrc, ble.sh)
    └── zsh/                     # Zsh environment (zshrc, fzf-tab, autosuggestions, compinit)
```

---

## 💻 Setting Up a New Mac

Open Terminal.app on a fresh Mac and run:

```bash
mkdir -p ~/projects && cd ~/projects
git clone https://github.com/<YOUR_USERNAME>/shell-settings.git config-settings
cd config-settings
chmod +x install.sh
./install.sh
```
