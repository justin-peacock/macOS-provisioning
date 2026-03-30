# macOS Provisioner

Provisioning scripts for a fresh macOS install or rebuild. There are two entry points:

- `./setup.sh` for a full workstation setup
- `./setup-minimal.sh` for a lighter setup, such as a MacBook Air

Both scripts install Homebrew, development tools and applications (via Brewfiles), macOS defaults, VS Code settings, and Oh My Zsh. The full setup also installs dotfiles.

## Usage

First, clone the repository.

```shell
git clone https://github.com/justin-peacock/macOS-provisioning.git
```

Then, navigate to the repository directory.

```shell
cd macOS-provisioning
```

Finally, run one of the scripts.

```shell
./setup.sh
./setup-minimal.sh
```

Use `--dry-run` to validate the Brewfile without making changes. It exits non-zero if any dependencies are missing.

```shell
./setup.sh --dry-run
./setup-minimal.sh --dry-run
```

## What does it do?

- Installs Homebrew (detects ARM vs Intel path automatically)
- Installs formulae and casks via `brew bundle` with a Brewfile
- Installs global npm packages and configures `corepack`
- Applies macOS defaults (Finder, Dock, keyboard, screenshots, etc.)
- Merges managed VS Code settings (preserves existing user settings)
- Installs Oh My Zsh
- Installs dotfiles (full setup only)

## Adding tools or apps

Add a line to the relevant Brewfile:

```ruby
brew "formula-name"    # CLI tool
cask "cask-name"       # GUI application
```

Verify names at [formulae.brew.sh](https://formulae.brew.sh/).

## Recommended Plugins for Oh My Zsh

- [brew](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/brew) — aliases for common brew commands
- [composer](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/composer) — completion and aliases for Composer
- [docker](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker) — auto-completion and aliases for Docker
- [docker-compose](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker-compose) — completion and aliases for docker-compose
- [git](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git) — many aliases and useful functions for git
- [npm](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/npm) — completion and aliases for npm

### Adding Plugins

Edit `~/.zshrc` and add plugin names to the `plugins` array:

```shell
plugins=(git brew composer docker docker-compose npm)
```
