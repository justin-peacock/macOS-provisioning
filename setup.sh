#!/usr/bin/env bash
set -e

# Check for Homebrew, install if not present
echo "Checking for Homebrew..."
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Update and upgrade Homebrew
echo "Updating Homebrew..."
brew update
brew upgrade

# Install command-line tools
echo "Installing command-line tools..."
cli_tools=(
    wget
    git
    git-lfs
    git-flow
    git-extras
    ssh-copy-id
    composer
    node
    cloudflared
)
for tool in "${cli_tools[@]}"; do
  brew install "$tool"
done

# Update npm and install global npm packages
echo "Updating npm and installing global npm packages..."
npm install -g npm
npm install -g gulp-cli yarn

# Install applications
echo "Installing applications..."
cask_apps=(
    1password
    alfred
    bambu-studio
    docker
    figma
    firefox-developer-edition
    google-drive
    imageoptim
    inkscape
    iterm2
    font-monaspace
    openinterminal
    phpstorm
    private-internet-access
    raspberry-pi-imager
    rectangle
    resilio-sync
    sequel-ace
    slack
    sourcetree
    the-unarchiver
    transmit
    vscodium
)
for app in "${cask_apps[@]}"; do
  brew install --cask "$app"
done

# Clean up Homebrew
echo "Cleaning up Homebrew..."
brew cleanup

# Install Oh My Zsh
echo "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
