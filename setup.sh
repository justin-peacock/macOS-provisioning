#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Logging helpers
info() { echo -e "\033[0;34m▶ $*\033[0m"; }
success() { echo -e "\033[0;32m✔ $*\033[0m"; }
error() { echo -e "\033[0;31m✖ $*\033[0m" >&2; }

# Detect Homebrew path based on architecture
if [[ "$(uname -m)" == "arm64" ]]; then
  BREW_PREFIX="/opt/homebrew"
else
  BREW_PREFIX="/usr/local"
fi
BREW_BIN="$BREW_PREFIX/bin/brew"

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
    BREW_SHELLENV_LINE="eval \"\$(${BREW_BIN} shellenv)\""
    grep -Fqx "$BREW_SHELLENV_LINE" "$HOME/.zprofile" 2>/dev/null || echo "$BREW_SHELLENV_LINE" >>"$HOME/.zprofile"
    eval "$("$BREW_BIN" shellenv)"
  fi
fi

if [[ "$DRY_RUN" -eq 0 ]]; then
  info "Updating Homebrew..."
  brew update
  brew upgrade
  success "Homebrew ready"
fi

# ── Brew Bundle ──────────────────────────────────────────────────────────────

if [[ "$DRY_RUN" -eq 1 ]]; then
  info "Checking Brewfile contents..."
  brew bundle check --file="$SCRIPT_DIR/Brewfile" --verbose || true
  success "Dry run complete"
  exit 0
else
  info "Installing formulae and casks via Brewfile..."
  brew bundle --file="$SCRIPT_DIR/Brewfile" --no-lock
  success "Brewfile installed"

  git lfs install
  success "git-lfs activated"
fi

# ── npm ───────────────────────────────────────────────────────────────────────

info "Updating npm and installing global packages..."
corepack enable
npm install -g npm prettier
success "npm packages installed"

mkcert -install
success "Local development certificates configured"

# ── macOS defaults ────────────────────────────────────────────────────────────

info "Configuring macOS defaults..."

# Finder: show hidden files, path bar, status bar, expand save/print dialogs
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Finder: show all file extensions, disable extension change warning
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Finder: avoid .DS_Store on network and USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Finder: show ~/Library
chflags nohidden ~/Library

# Keyboard: faster key repeat, disable auto-correct and smart substitutions
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Dock: auto-hide, no recent apps, minimize with scale effect
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mineffect -string "scale"

# Screenshots: PNG, no shadow, copy to clipboard
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true
# Cmd+Shift+3/4 saves to file; Cmd+Ctrl+Shift+3/4 copies to clipboard.
# To default to clipboard, open Screenshot (Cmd+Shift+5) → Options → Save to Clipboard.
# This preference is remembered per-user but not scriptable via defaults.

# Keyboard shortcut: Ctrl+Shift+T → "New Terminal at Folder" in Finder
# shellcheck disable=SC2016
defaults write com.apple.finder NSUserKeyEquivalents -dict-add "New Terminal at Folder" '^$t'

killall Finder Dock SystemUIServer 2>/dev/null || true
success "macOS defaults configured"

# ── VS Code ───────────────────────────────────────────────────────────────────

info "Configuring VS Code..."
VSCODE_SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
VSCODE_SETTINGS_FILE="$VSCODE_SETTINGS_DIR/settings.json"
mkdir -p "$VSCODE_SETTINGS_DIR"

[ -f "$VSCODE_SETTINGS_FILE" ] || echo '{}' >"$VSCODE_SETTINGS_FILE"

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

success "Setup complete! Restart your terminal to apply all changes."
