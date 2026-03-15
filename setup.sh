#!/usr/bin/env bash
set -euo pipefail

# Logging helpers
info() { echo -e "\033[0;34m▶ $*\033[0m"; }
success() { echo -e "\033[0;32m✔ $*\033[0m"; }
error() { echo -e "\033[0;31m✖ $*\033[0m" >&2; }

brew_shellenv_path() {
  command -v brew
}

# ── Options ───────────────────────────────────────────────────────────────────

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
  info "Dry run enabled (no changes will be made)"
fi

# ── Homebrew ──────────────────────────────────────────────────────────────────

info "Checking for Homebrew..."
if ! command -v brew &>/dev/null; then
  if [[ "$DRY_RUN" -eq 1 ]]; then
    error "Homebrew not found. Install Homebrew first, then re-run with --dry-run."
    exit 1
  else
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    BREW_BIN="$(brew_shellenv_path)"
    BREW_SHELLENV_LINE="eval \"\$(${BREW_BIN} shellenv)\""
    grep -Fqx "$BREW_SHELLENV_LINE" "$HOME/.zprofile" 2>/dev/null || echo "$BREW_SHELLENV_LINE" >>"$HOME/.zprofile"
    eval "$("$BREW_BIN" shellenv)"
  fi
fi

if [[ "$DRY_RUN" -eq 0 ]]; then
  info "Updating Homebrew..."
  brew update
  brew upgrade --greedy
  success "Homebrew ready"
fi

# ── CLI tools ─────────────────────────────────────────────────────────────────

FORMULAE=(
  composer
  ddev/ddev/ddev
  editorconfig
  mkcert
  openssl
  wget
  git
  git-lfs
  git-flow
  git-extras
  gh
  ssh-copy-id
  node
  cloudflared
  railway
  shfmt
  shellcheck
  speedtest-cli
)

if [[ "$DRY_RUN" -eq 1 ]]; then
  info "Checking formula availability..."
  missing_formulae=()
  for formula in "${FORMULAE[@]}"; do
    if ! brew info --formula "$formula" &>/dev/null; then
      missing_formulae+=("$formula")
    fi
  done
else
  info "Installing command-line tools..."
  brew install "${FORMULAE[@]}"
  success "CLI tools installed"

  git lfs install
  success "git-lfs activated"
fi

# ── npm ───────────────────────────────────────────────────────────────────────

if [[ "$DRY_RUN" -eq 0 ]]; then
  info "Updating npm and installing global packages..."
  npm install -g npm gulp-cli yarn prettier
  success "npm packages installed"

  mkcert -install
  success "Local development certificates configured"
fi

# ── Applications ──────────────────────────────────────────────────────────────

CASKS=(
  1password
  adobe-creative-cloud
  alfred
  autodesk-fusion
  bambu-studio
  chatgpt
  discord
  elgato-camera-hub
  figma
  google-drive
  imageoptim
  inkscape
  iterm2
  logi-options+
  microsoft-teams
  notion
  openinterminal
  orbstack
  private-internet-access
  raspberry-pi-imager
  rectangle
  resilio-sync
  sequel-ace
  sip-app
  slack
  the-unarchiver
  transmit
  visual-studio-code
  zoom
)

if [[ "$DRY_RUN" -eq 1 ]]; then
  info "Checking cask availability..."
  missing_casks=()
  for cask in "${CASKS[@]}"; do
    if ! brew info --cask "$cask" &>/dev/null; then
      missing_casks+=("$cask")
    fi
  done
else
  info "Installing applications..."
  brew install --cask "${CASKS[@]}"
  success "Applications installed"

  info "Cleaning up Homebrew..."
  brew cleanup
  success "Homebrew cleaned up"
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  if [[ ${#missing_formulae[@]} -gt 0 ]]; then
    error "Missing formulae:"
    for formula in "${missing_formulae[@]}"; do
      echo "  - $formula"
    done
  else
    success "All formulae found in Homebrew"
  fi

  if [[ ${#missing_casks[@]} -gt 0 ]]; then
    error "Missing casks:"
    for cask in "${missing_casks[@]}"; do
      echo "  - $cask"
    done
  else
    success "All casks found in Homebrew"
  fi

  if [[ ${#missing_formulae[@]} -gt 0 || ${#missing_casks[@]} -gt 0 ]]; then
    exit 1
  fi

  success "Dry run complete"
  exit 0
fi

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
  python3 - "$VSCODE_SETTINGS_FILE" <<'PY'
import json
import shutil
import sys
from pathlib import Path

settings_file = Path(sys.argv[1])
managed_settings = {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": True,
    "editor.tabSize": 2,
    "editor.insertSpaces": True,
    "editor.rulers": [80, 120],
    "editor.wordWrap": "off",
    "editor.minimap.enabled": False,
    "editor.bracketPairColorization.enabled": True,
    "files.trimTrailingWhitespace": True,
    "files.insertFinalNewline": True,
    "files.trimFinalNewlines": True,
    "files.autoSave": "onFocusChange",
    "git.autofetch": True,
    "git.confirmSync": False,
    "workbench.startupEditor": "none",
    "[shellscript]": {"editor.defaultFormatter": "foxundermoon.shell-format"},
}

try:
    settings = json.loads(settings_file.read_text())
except json.JSONDecodeError:
    backup = settings_file.with_suffix(".json.bak")
    shutil.copy2(settings_file, backup)
    settings = {}

settings.update(managed_settings)
settings_file.write_text(json.dumps(settings, indent=2) + "\n")
PY
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

# ── Oh My Zsh ─────────────────────────────────────────────────────────────────

info "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
success "Oh My Zsh ready"

# ── Dotfiles ──────────────────────────────────────────────────────────────────

info "Installing dotfiles..."
if [ ! -d "$HOME/dotfiles" ]; then
  git clone https://github.com/justin-peacock/dotfiles.git "$HOME/dotfiles"
fi
bash "$HOME/dotfiles/install.sh"
success "Dotfiles installed"

success "Setup complete! Restart your terminal to apply all changes."
