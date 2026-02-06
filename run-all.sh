#!/bin/sh

# install build deps
./install-build-dependencies.sh

# install mise for installing runtime environments
./install-mise.sh

# install all packages in order
./install-fish.sh
./install-nodejs.sh
./install-pnpm.sh
./install-bun.sh
./install-gemini-cli.sh
./install-opencode.sh
./install-mariadb-clients.sh
./install-vscode.sh
./install-vscode-insiders.sh
./install-antigravity.sh
./install-zed.sh
./install-agent-browser.sh
./install-android-studio.sh
./install-claude-code.sh
./install-direnv.sh
./install-google-chrome.sh
./install-helium-browser.sh
./install-kimi-code.sh
./install-pencil.sh
./install-uv.sh

# install stow for dotfiles management
./install-stow.sh

# update dotfiles
./install-dotfiles.sh
./install-hyprland-overrides.sh

# symlink vscode settings (after dotfiles are cloned)
./symlink-vscode.sh
./symlink-vscode-insiders.sh

# uninstall unwanted programs
./uninstall-unwanted-programs.sh

# change shell to fish
./change-shell.sh

# remove orphaned packages
./remove-orphans.sh
