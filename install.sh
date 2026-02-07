#!/bin/bash

# Exit on error
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Installing dotfiles from $SCRIPT_DIR..."

# Create necessary directories
echo "Creating configuration directories..."
mkdir -p "$HOME/.config/zsh"
mkdir -p "$HOME/.config/git"
mkdir -p "$HOME/.config/nvim"

# Create symlinks
echo "Creating symlinks..."

# Zsh configuration
echo "Processing $HOME/.config/zsh/.zshrc..."
ln -sf "$SCRIPT_DIR/zsh/.zshrc" "$HOME/.config/zsh/.zshrc"

echo "Processing $HOME/.config/zsh/prompt.zsh..."
ln -sf "$SCRIPT_DIR/zsh/prompt.zsh" "$HOME/.config/zsh/prompt.zsh"

echo "Processing $HOME/.config/zsh/aliases.zsh..."
ln -sf "$SCRIPT_DIR/zsh/aliases.zsh" "$HOME/.config/zsh/aliases.zsh"

echo "Processing $HOME/.config/zsh/functions.zsh..."
ln -sf "$SCRIPT_DIR/zsh/functions.zsh" "$HOME/.config/zsh/functions.zsh"

echo "Processing $HOME/.config/zsh/local.zsh..."
ln -sf "$SCRIPT_DIR/zsh/local.zsh" "$HOME/.config/zsh/local.zsh"

# Git configuration
echo "Processing $HOME/.config/git/config..."
ln -sf "$SCRIPT_DIR/git/config" "$HOME/.config/git/config"

echo "Processing $HOME/.config/git/ignore..."
ln -sf "$SCRIPT_DIR/git/ignore" "$HOME/.config/git/ignore"

# Neovim configuration
echo "Processing $HOME/.config/nvim/init.vim..."
if [ -f "$SCRIPT_DIR/nvim/init.vim" ]; then
    ln -sf "$SCRIPT_DIR/nvim/init.vim" "$HOME/.config/nvim/init.vim"
else
    echo "Warning: $SCRIPT_DIR/nvim/init.vim does not exist! Skipping..."
fi

# Create compatibility symlinks
echo "Creating compatibility symlinks..."

# Create .zshrc symlink in home directory
echo "Creating .zshrc symlink in home directory..."
ln -sf "$HOME/.config/zsh/.zshrc" "$HOME/.zshrc"

# Configure git identity if not already set
CURRENT_NAME=$(git config --global user.name 2>/dev/null || true)
CURRENT_EMAIL=$(git config --global user.email 2>/dev/null || true)

if [ -z "$CURRENT_NAME" ] || [ -z "$CURRENT_EMAIL" ]; then
    echo ""
    echo "Git identity not configured. Let's set it up."
    if [ -z "$CURRENT_NAME" ]; then
        printf "Enter your full name for git commits: "
        read GIT_NAME
        git config --global user.name "$GIT_NAME"
    fi
    if [ -z "$CURRENT_EMAIL" ]; then
        printf "Enter your email for git commits: "
        read GIT_EMAIL
        git config --global user.email "$GIT_EMAIL"
    fi
    echo "Git identity configured."
fi

echo ""
echo "Dotfiles installation complete!"
echo "Please restart your terminal or run 'source ~/.zshrc' to apply changes." 