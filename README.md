# ⚙️ Config & Settings (Universal Dotfiles for macOS & Linux)

A universal, modular, and portable repository of workstation configurations for **macOS** and **Linux (Ubuntu/Debian, Arch Linux, Fedora)**:
**Zsh, Bash, Ghostty, Neovim, Starship, Tmux, Git + Delta, Yazi, Bat, Antigravity IDE, Homebrew / Linuxbrew / Pacman / APT / DNF**.

All configurations are linked via **symbolic links (symlinks)**: any edits to your config files are immediately reflected in this repository.

---

## 📁 Repository Structure

```text
config-settings/
├── Brewfile                     # Homebrew / Linuxbrew CLI packages, fonts & terminals
├── Brewfile.apps                # macOS GUI applications (Chrome, Telegram, Discord...)
├── install.sh                   # UNIVERSAL installer (auto-detects macOS or Linux)
├── README.md                    # This guide
├── .gitignore                   # Ignores system junk and local secrets
├── .github/workflows/ci.yml     # CI pipeline (ShellCheck + macOS/Linux installer tests)
├── config/
│   ├── ghostty/config           # Ghostty terminal config (TokyoNight, splits, AI scrollback)
│   ├── git/                     # XDG Git config (delta, aliases) & global ignore
│   │   ├── config
│   │   └── ignore
│   ├── nvim/                    # Full Neovim config (init.lua + lazy-lock.json)
│   ├── starship.toml            # Optimized TokyoNight shell prompt
│   ├── tmux/tmux.conf           # Tmux config (TokyoNight bar, 1-indexed, vim keys)
│   └── yazi/yazi.toml           # Yazi terminal file manager config
├── ide/
│   └── antigravity-ide/         # Antigravity IDE settings and extension list
│       ├── settings.json
│       └── extensions.txt
├── scripts/
│   ├── lib.sh                   # Shared installer library (symlinks, Brew, plugins, doctor)
│   ├── install-macos.sh         # Standalone installer for macOS
│   ├── install-linux.sh         # Standalone installer for Linux (Arch, Ubuntu/Debian, Fedora)
│   ├── macos-defaults.sh        # Developer-friendly macOS system preferences
│   └── snapshot.sh              # Captures newly installed Brew packages and IDE extensions
└── shell/
    ├── common.sh                # SHARED by Zsh and Bash (PATH, env, aliases, FZF, bat, yazi)
    ├── bash/                    # Bash environment (bashrc, bash_profile, inputrc, ble.sh)
    └── zsh/                     # Zsh environment (zshrc, fzf-tab, autosuggestions, compinit)
```

---

## 🚀 Pushing This Repository to Git (First Time)

1. Go to the repository folder:
   ```bash
   cd ~/projects/config-settings
   ```

2. Connect a remote repository on GitHub / GitLab and push:
   ```bash
   # Using GitHub CLI (gh):
   gh auth login
   gh repo create shell-settings --private --source=. --remote=origin --push

   # Or manually to an existing remote:
   git remote add origin git@github.com:<YOUR_USERNAME>/shell-settings.git
   git push -u origin main
   ```

---

## 💻 Setting Up a New Machine

### 1. Universal Method (Recommended)
The `install.sh` script detects the operating system (macOS or a Linux distribution) and runs the matching setup flow:

```bash
mkdir -p ~/projects && cd ~/projects
git clone <YOUR_REPOSITORY_URL> config-settings
cd config-settings
chmod +x install.sh
./install.sh
```

---

### 2. Platform-Specific Installers

If you prefer to run the setup directly for a specific platform:

#### 🍏 macOS (`./scripts/install-macos.sh` or `./install.sh --macos`):
- Installs **Xcode Command Line Tools** and **Homebrew**.
- Installs all packages from `Brewfile` (`fzf`, `eza`, `bat`, `git-delta`, `zoxide`, `starship`, `neovim`, `tmux`, `yazi`, Nerd Fonts, Ghostty, etc.).
- Installs Zsh plugins (`fzf-tab`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-completions`) and `ble.sh` for Bash.
- Backs up existing configs to `~/.dotfiles-backup/<timestamp>/` and creates symlinks.
- Installs Antigravity IDE extensions and restores Neovim plugins from `lazy-lock.json`.
- Optional GUI applications (`Chrome`, `Discord`, `Telegram`, `Maccy`, etc.) and macOS developer defaults:
  ```bash
  ./install.sh --apps --macos-defaults
  ```

#### 🐧 Linux (`./scripts/install-linux.sh` or `./install.sh --linux`):
Automatically detects the distribution family and ensures a complete CLI environment:
- **Arch Linux / Manjaro / EndeavourOS**:
  Uses `pacman` to install `base-devel`, `git`, `zsh`, `fzf`, `ripgrep`, `fd`, `bat`, `git-delta`, `eza`, `zoxide`, `starship`, `yazi`, `neovim`, `tmux`, and Nerd Fonts.
- **Ubuntu / Debian / Pop!_OS / Mint**:
  Uses `apt-get` for core packages, creates `~/.local/bin/fd` and `~/.local/bin/bat` compatibility symlinks, installs `starship`, `zoxide`, `eza`, and downloads JetBrains Mono Nerd Font into `~/.local/share/fonts`.
- **Fedora / RHEL / Rocky**:
  Uses `dnf` for developer tools, `starship`, `zoxide`, `eza`, `bat`, and `git-delta`.
- **Homebrew on Linux (Linuxbrew)**:
  Automatically installs **Homebrew (Linuxbrew)** if not already present on the system and bundles cross-platform CLI tools from `Brewfile` (can be skipped with `--no-brew`).
- Creates symlinks for shell, nvim, tmux, git, yazi, ghostty, and IDE settings.

---

### ⚙️ Installer Flags

Flags can be passed to either the universal `./install.sh` or the platform scripts:

| Flag | Description |
|---|---|
| `./install.sh --link-only` | Only create / update symlinks without installing packages |
| `./install.sh --dry-run` | Preview all actions without modifying any files or packages |
| `./install.sh --check` | Run a health check on symlinks, CLI tools, and Zsh plugins |
| `./install.sh --no-brew` | (macOS & Linux) Skip Homebrew / Linuxbrew installation & bundle |
| `./install.sh --no-pkg` | (Linux) Skip native system package manager installation |
| `./install.sh --apps` | (macOS) Also install GUI applications from `Brewfile.apps` |
| `./install.sh --macos-defaults` | (macOS) Apply developer system preferences (fast key repeat, Finder, Dock) |
| `./install.sh --macos` | Force the macOS setup flow |
| `./install.sh --linux` | Force the Linux setup flow |

---

## 🔄 Keeping Changes in Sync

Because all configuration files are linked via **symbolic links**:
- Editing `~/.zshrc`, `~/.config/ghostty/config`, `~/.config/nvim/init.lua`, `~/.tmux.conf`, or `~/.config/git/config` directly updates the files inside this repository.
- Jump to the repository from anywhere:
  ```bash
  dotfiles
  ```

### Saving Newly Installed Packages & Extensions to Git:
Whenever you install new Homebrew formulae/casks or IDE extensions:
```bash
cd ~/projects/config-settings
./scripts/snapshot.sh
git add -A
git commit -m "chore: update configs and packages"
git push
```
The `snapshot.sh` script detects newly installed packages and appends them to `Brewfile`, and updates `ide/antigravity-ide/extensions.txt`.

---

## 🔒 Local Settings and Secrets (Tokens, Keys, Git Identity)

- **Shell secrets:** Never commit API keys or personal tokens (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, work tokens) to the repository. Put them in local untracked files created automatically by the installer:
  - `~/.zshrc.local` — sourced at the end of `.zshrc`.
  - `~/.bashrc.local` — sourced at the end of `.bashrc`.
  ```bash
  export OPENAI_API_KEY="sk-..."
  export ANTHROPIC_API_KEY="sk-..."
  export GITHUB_TOKEN="ghp_..."
  ```
- **Git identity:** Shared Git settings and `delta` integration live in `~/.config/git/config`, while your personal `[user]` `name` and `email` remain untouched in `~/.gitconfig`.

---

## ⌨️ Key Shortcuts and Terminal Navigation

- **↑ / ↓**: Prefix history search (type `docker` and press `↑` to cycle only through commands starting with `docker`).
- **Tab**: Interactive completion menu via `fzf-tab` with live previews (`eza` for directories, `bat` for files, `delta` for `git diff`).
- **Ctrl + R**: Full-text fuzzy search across command history.
- **Ctrl + T / Alt + C**: Fuzzy-pick files (with `bat` preview) or `cd` into subdirectories.
- **→ / End / Ctrl + Space**: Accept the entire grey autosuggestion from history.
- **Alt + →**: Accept the autosuggestion one word at a time.
- **Alt + /**: Complete the current word from history.
- **Ctrl + X, Ctrl + E**: Open the current command line in Neovim for full editing.
- `y`: Launch the `yazi` terminal file manager and automatically `cd` into the last visited folder on exit.
- `reload`: Reload shell configuration without closing the terminal.
