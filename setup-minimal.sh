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
# If brew exists at the expected path but isn't on PATH, activate it
if [[ -x "$BREW_BIN" ]] && ! command -v brew &>/dev/null; then
  eval "$("$BREW_BIN" shellenv)"
fi

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
  info "Checking Brewfile.minimal contents..."
  if brew bundle check --file="$SCRIPT_DIR/Brewfile.minimal" --verbose; then
    success "Dry run complete — all dependencies satisfied"
  else
    error "Dry run failed — missing dependencies listed above"
    exit 1
  fi
  exit 0
else
  info "Installing formulae and casks via Brewfile.minimal..."
  brew bundle --file="$SCRIPT_DIR/Brewfile.minimal"
  success "Brewfile installed"

  git lfs install
  success "git-lfs activated"
fi

# ── Node via fnm ─────────────────────────────────────────────────────────────

info "Installing Node LTS via fnm..."
eval "$(fnm env)"
fnm install --lts
fnm use lts-latest

# Persist fnm initialization so Node is available in new shell sessions
# shellcheck disable=SC2016
FNM_ENV_LINE='eval "$(fnm env)"'
grep -Fqx "$FNM_ENV_LINE" "$HOME/.zshrc" 2>/dev/null || echo "$FNM_ENV_LINE" >>"$HOME/.zshrc"
success "Node LTS installed via fnm"

# ── npm ───────────────────────────────────────────────────────────────────────

info "Installing global npm packages..."
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

# Back up and reset if settings file contains invalid JSON
if ! jq empty "$VSCODE_SETTINGS_FILE" 2>/dev/null; then
  cp "$VSCODE_SETTINGS_FILE" "$VSCODE_SETTINGS_FILE.bak"
  echo '{}' >"$VSCODE_SETTINGS_FILE"
fi

MANAGED_SETTINGS=$(cat <<'EOF'
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
)

jq --argjson managed "$MANAGED_SETTINGS" '. + $managed' "$VSCODE_SETTINGS_FILE" >"$VSCODE_SETTINGS_FILE.tmp" \
  && mv "$VSCODE_SETTINGS_FILE.tmp" "$VSCODE_SETTINGS_FILE"

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
