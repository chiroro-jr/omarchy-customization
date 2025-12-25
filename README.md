# Omarchy Customization

This repository contains a collection of shell scripts to automate the customization and setup of the **Omarchy** Linux (based on Arch Linux).

It handles the installation of packages, development tools, and configuration files (dotfiles) to create a consistent development environment.

## Prerequisites

- **Omarchy Linux** installation.
- **yay** (AUR helper) must be installed.

## Usage

To set up the environment, simply run the master script:

```bash
./run-all.sh
```

## What it does

The `run-all.sh` script orchestrates the following process:

1.  **System Setup**:
    - Installs essential build dependencies.
    - Installs `mise` for managing runtime environments.
    - Installs `stow` for dotfiles management.

2.  **Package Installation**:
    - **Shell**: Fish
    - **Development**: Node.js, pnpm, Bun, Gemini CLI, Opencode, MariaDB Clients.
    - **Editors**: VS Code, VS Code Insiders, Zed, Antigravity.

3.  **Configuration & Dotfiles**:
    - Clones dotfiles from `https://github.com/chiroro-jr/dotfiles`.
    - Uses `stow` to apply configurations for `fish`, `git`, `zed`, and `opencode`.
    - Manually symlinks settings for VS Code and VS Code Insiders.
    - Applies custom **Hyprland** overrides (`hyprland-overrides.conf`) by injecting a source line into the main config.

4.  **Finalization**:
    - Uninstalls unwanted default programs.
    - Changes the default shell to `fish`.
    - Removes orphaned packages.

## Scripts Overview

- `run-all.sh`: The main entry point that executes all other scripts in the correct order.
- `install-*.sh`: Scripts dedicated to installing specific tools or packages (e.g., `install-fish.sh`, `install-vscode.sh`).
- `symlink-*.sh`: Scripts for linking configuration files that require special handling (VS Code).
- `change-shell.sh`: Sets `fish` as the default user shell.
- `remove-orphans.sh`: Cleans up unused dependencies using `pacman -Qtdq`.
