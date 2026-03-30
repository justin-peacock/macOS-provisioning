# Copilot Instructions

## Repository Overview

This is a macOS provisioning repo with two entry points (`setup.sh` and `setup-minimal.sh`) that bootstrap a fresh macOS install. They install Homebrew, manage packages via Brewfiles, configure macOS defaults, set up VS Code, and install Oh My Zsh.

## Structure

- `setup.sh` — full workstation provisioning
- `setup-minimal.sh` — lighter setup (e.g., MacBook Air), uses `fnm` for Node version management
- `Brewfile` — Homebrew formulae and casks for `setup.sh`
- `Brewfile.minimal` — Homebrew formulae and casks for `setup-minimal.sh`
- No build system or test suite exists

## Running the Scripts

```shell
./setup.sh           # full install
./setup-minimal.sh   # minimal install
./setup.sh --dry-run # validate Brewfile without making changes
```

Both scripts use `set -euo pipefail` — they exit immediately on any error, unset variable, or failed pipe.

## Key Conventions

- **Packages** are managed via `Brewfile` / `Brewfile.minimal` using `brew bundle`
- **Global npm packages** are installed with `npm install -g` after updating npm itself
- Homebrew path is detected by architecture (`/opt/homebrew` for ARM, `/usr/local` for Intel)
- The scripts are idempotent — `brew bundle` and Oh My Zsh both handle re-runs gracefully
- VS Code settings are merged using `jq` (preserves existing user settings, applies managed defaults on top)
- `--dry-run` validates the Brewfile and exits non-zero if dependencies are missing

## Adding Tools or Apps

- **CLI tool**: add a `brew "formula-name"` line to the relevant Brewfile
- **GUI app**: add a `cask "cask-name"` line to the relevant Brewfile
- **npm global package**: add to the `npm install -g` line in the script
- Verify cask names at [formulae.brew.sh/cask](https://formulae.brew.sh/cask/) and formula names at [formulae.brew.sh](https://formulae.brew.sh/)
