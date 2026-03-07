# Copilot Instructions

## Repository Overview

This is a single-file macOS provisioning script (`setup.sh`) that bootstraps a fresh macOS install. It installs Homebrew, a curated set of CLI tools and cask applications, global npm packages, and Oh My Zsh.

## Structure

- `setup.sh` — the entire provisioning logic; all changes go here
- No build system, package manager, or test suite exists

## Running the Script

```shell
./setup.sh
```

The script uses `set -e` — it exits immediately on any error.

## Key Conventions

- **CLI tools** are installed via `brew install` using the `cli_tools` array
- **GUI applications** are installed via `brew install --cask` using the `cask_apps` array
- **Global npm packages** are installed with `npm install -g` after updating npm itself
- Comment out (don't delete) apps temporarily excluded from installation (see `# autodesk-fusion` pattern)
- Homebrew is assumed to be at `/opt/homebrew` (Apple Silicon path)
- The script is idempotent for Oh My Zsh (checks `~/.oh-my-zsh` before installing), but Homebrew installs are not explicitly guarded — `brew install` handles already-installed packages gracefully

## Adding Tools or Apps

- **CLI tool**: add the Homebrew formula name to the `cli_tools` array
- **GUI app**: add the Homebrew cask name to the `cask_apps` array
- **npm global package**: add to the `npm install -g` line
- Verify cask names at [formulae.brew.sh/cask](https://formulae.brew.sh/cask/) and formula names at [formulae.brew.sh](https://formulae.brew.sh/)
