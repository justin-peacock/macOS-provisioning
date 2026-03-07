#!/usr/bin/env bash
set -euo pipefail

# Logging helpers
info() { echo -e "\033[0;34m▶ $*\033[0m"; }
success() { echo -e "\033[0;32m✔ $*\033[0m"; }
error() { echo -e "\033[0;31m✖ $*\033[0m" >&2; }

# ── Homebrew ──────────────────────────────────────────────────────────────────

info "Checking for Homebrew..."
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$HOME/.zprofile"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

info "Updating Homebrew..."
brew update
brew upgrade --greedy
success "Homebrew ready"

# ── CLI tools ─────────────────────────────────────────────────────────────────

info "Installing command-line tools..."
brew install \
  wget \
  git \
  git-lfs \
  ssh-copy-id \
  composer \
  cloudflared \
  fnm \
  shfmt \
  shellcheck \
  htop \
  tmux \
  mtr \
  nmap \
  jq \
  gh \
  httpie
success "CLI tools installed"

git lfs install
success "git-lfs activated"

# Bootstrap Node LTS via fnm
eval "$(fnm env)"
fnm install --lts
fnm use lts-latest
success "Node LTS installed via fnm"

# ── npm ───────────────────────────────────────────────────────────────────────

info "Installing global npm packages..."
npm install -g npm prettier
success "npm packages installed"

# ── Applications ──────────────────────────────────────────────────────────────

info "Installing applications..."
brew install --cask \
  1password \
  iterm2 \
  rectangle \
  visual-studio-code
success "Applications installed"

info "Cleaning up Homebrew..."
brew cleanup
success "Homebrew cleaned up"

# ── macOS defaults ────────────────────────────────────────────────────────────

info "Configuring macOS defaults..."

# Finder: show hidden files, expand save/print dialogs, skip app quarantine prompt
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Keyboard: faster key repeat
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Dock: auto-hide, no recent apps
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false

# Screenshots: save to Desktop as PNG without drop shadow
defaults write com.apple.screencapture location -string "$HOME/Desktop"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

killall Finder Dock 2>/dev/null || true
success "macOS defaults configured"

# ── VS Code ───────────────────────────────────────────────────────────────────

info "Configuring VS Code..."
VSCODE_SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
VSCODE_SETTINGS_FILE="$VSCODE_SETTINGS_DIR/settings.json"
mkdir -p "$VSCODE_SETTINGS_DIR"

if [ -f "$VSCODE_SETTINGS_FILE" ]; then
  python3 -c "
import json
with open('$VSCODE_SETTINGS_FILE', 'r') as f:
    settings = json.load(f)
settings.update({
    'editor.defaultFormatter': 'esbenp.prettier-vscode',
    'editor.formatOnSave': True,
    'editor.tabSize': 2,
    'editor.insertSpaces': True,
    'editor.rulers': [80, 120],
    'editor.wordWrap': 'off',
    'editor.minimap.enabled': False,
    'editor.bracketPairColorization.enabled': True,
    'files.trimTrailingWhitespace': True,
    'files.insertFinalNewline': True,
    'files.trimFinalNewlines': True,
    'files.autoSave': 'onFocusChange',
    'git.autofetch': True,
    'git.confirmSync': False,
    'workbench.startupEditor': 'none',
    '[shellscript]': {'editor.defaultFormatter': 'foxundermoon.shell-format'},
})
with open('$VSCODE_SETTINGS_FILE', 'w') as f:
    json.dump(settings, f, indent=2)
"
else
  cat >"$VSCODE_SETTINGS_FILE" <<'EOF'
{
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true,
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "editor.rulers": [80, 120],
  "editor.wordWrap": "off",
  "editor.minimap.enabled": false,
  "editor.bracketPairColorization.enabled": true,
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "files.trimFinalNewlines": true,
  "files.autoSave": "onFocusChange",
  "git.autofetch": true,
  "git.confirmSync": false,
  "workbench.startupEditor": "none",
  "[shellscript]": {
    "editor.defaultFormatter": "foxundermoon.shell-format"
  }
}
EOF
fi

if command -v code &>/dev/null; then
  code --install-extension esbenp.prettier-vscode
  code --install-extension foxundermoon.shell-format
fi
success "VS Code configured"

# ── Dotfiles ──────────────────────────────────────────────────────────────────

info "Installing dotfiles..."
if [ ! -d "$HOME/dotfiles" ]; then
  git clone https://github.com/justin-peacock/dotfiles.git "$HOME/dotfiles"
fi
bash "$HOME/dotfiles/install.sh"
success "Dotfiles installed"

# ── Oh My Zsh ─────────────────────────────────────────────────────────────────

info "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
success "Oh My Zsh ready"

success "Setup complete! Restart your terminal to apply all changes."
