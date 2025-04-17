# macOS Provisioner

This is a simple script to provision a macOS machine with the tools and applications I use on a daily basis. It installs homebrew, Oh My Zsh, and a list of applications and tools that I use. The script is designed to be run on a fresh installation of macOS.

## Usage

First, clone the repository.

```shell
git clone https://github.com/justin-peacock/macOS-provisioning.git
```

Then, navigate to the repository directory.

```shell
cd macOS-provisioning
```

Finally, run the script.

```shell
./setup.sh
```

## What does it do?

- Installs Homebrew
- Installs applications using Homebrew
- Installs Oh My Zsh

## Available tools

### Browsers

- [Firefox Developer Edition](https://www.mozilla.org/en-US/firefox/developer/)

### Editors

- [PHPStorm](https://www.jetbrains.com/phpstorm/)
- [VSCodium](https://vscodium.com/)
- [Figma](https://www.figma.com/)

### Development Tools

- [Composer](https://getcomposer.org/)
- [Docker](https://www.docker.com/)
- [Node.js](https://nodejs.org/)
- [Yarn](https://yarnpkg.com/)
- [Gulp](https://gulpjs.com/)

### Utilities

- [1Password](https://1password.com/)
- [iTerm2](https://iterm2.com/)
- [Sequel Ace](https://sequel-ace.com/)
- [SourceTree](https://www.sourcetreeapp.com/)
- [Slack](https://slack.com/)
- [Rectangle](https://rectangleapp.com/)
- [The Unarchiver](https://theunarchiver.com/)

## Recommended Plugins for Oh My Zsh

- [1Password](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/1password) this plugin adds 1Password functionality to oh-my-zsh.
- [brew](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/brew) the plugin adds several aliases for common brew commands.
- [composer](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/composer) this plugin provides completion for composer, as well as aliases for frequent composer commands. It also adds Composer's global binaries to the PATH, using Composer if available.
- [docker](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker) this plugin adds auto-completion and aliases for docker.
- [docker-compose](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker-compose) this plugin provides completion for docker-compose as well as some aliases for frequent docker-compose commands.
- [drush](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/drush) this plugin adds aliases and functions for Drush, a command-line shell and Unix scripting interface for Drupal. It also adds completion for the `drush` command.
- [git](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git) the git plugin provides many aliases and a few useful functions.
- [npm](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/npm) the npm plugin provides completion as well as adding many useful aliases.
- [yarn](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/yarn) this plugin adds completion for the Yarn package manager, as well as some aliases for common Yarn commands.

### Adding Plugins

To add plugins to Oh My Zsh, edit the `~/.zshrc` file.

```shell
nano ~/.zshrc
```

Then add the plugin name to the `plugins` array.

```shell
# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git brew composer docker docker-compose drush npm yarn 1password)
```
