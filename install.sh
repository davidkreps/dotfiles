#!/bin/bash

# Exit on error
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Back up an existing regular file before creating a symlink
safe_link() {
    local target="$1" link="$2"
    if [ -e "$link" ] && [ ! -L "$link" ]; then
        echo "  Backing up existing $link to ${link}.backup"
        mv "$link" "${link}.backup"
    fi
    ln -sf "$target" "$link"
}

echo "Installing dotfiles from $SCRIPT_DIR..."

# Create necessary directories
echo "Creating configuration directories..."
mkdir -p "$HOME/.config/zsh"
mkdir -p "$HOME/.config/git"

# Create symlinks
echo "Creating symlinks..."

# Zsh configuration
echo "Processing $HOME/.config/zsh/.zshrc..."
safe_link "$SCRIPT_DIR/zsh/.zshrc" "$HOME/.config/zsh/.zshrc"

echo "Processing $HOME/.config/zsh/prompt.zsh..."
safe_link "$SCRIPT_DIR/zsh/prompt.zsh" "$HOME/.config/zsh/prompt.zsh"

echo "Processing $HOME/.config/zsh/aliases.zsh..."
safe_link "$SCRIPT_DIR/zsh/aliases.zsh" "$HOME/.config/zsh/aliases.zsh"

echo "Processing $HOME/.config/zsh/functions.zsh..."
safe_link "$SCRIPT_DIR/zsh/functions.zsh" "$HOME/.config/zsh/functions.zsh"

# Create local.zsh if it doesn't exist (not symlinked — this is a per-machine file)
if [ ! -f "$HOME/.config/zsh/local.zsh" ]; then
    echo "Creating $HOME/.config/zsh/local.zsh..."
    cat > "$HOME/.config/zsh/local.zsh" << 'LOCALEOF'
# Machine-specific settings (not version controlled)
# Add aliases, functions, environment variables, PATH additions, etc.
LOCALEOF
fi

# Git configuration
echo "Processing $HOME/.config/git/config..."
safe_link "$SCRIPT_DIR/git/config" "$HOME/.config/git/config"

echo "Processing $HOME/.config/git/ignore..."
safe_link "$SCRIPT_DIR/git/ignore" "$HOME/.config/git/ignore"

# Create compatibility symlinks
echo "Creating compatibility symlinks..."

# Create .zshrc symlink in home directory
echo "Creating .zshrc symlink in home directory..."
safe_link "$HOME/.config/zsh/.zshrc" "$HOME/.zshrc"

# Configure git identity in local (untracked) config file
GIT_LOCAL="$HOME/.config/git/local"

# Read current identity from the merged config (includes the local file)
CURRENT_NAME=$(git config user.name 2>/dev/null || true)
CURRENT_EMAIL=$(git config user.email 2>/dev/null || true)

if [ -z "$CURRENT_NAME" ] || [ -z "$CURRENT_EMAIL" ]; then
    echo ""
    echo "Git identity not configured. Let's set it up."
    if [ -z "$CURRENT_NAME" ]; then
        printf "Enter your full name for git commits: "
        read GIT_NAME
    fi
    if [ -z "$CURRENT_EMAIL" ]; then
        printf "Enter your email for git commits: "
        read GIT_EMAIL
    fi

    # Create git/local if it doesn't exist
    if [ ! -f "$GIT_LOCAL" ]; then
        cat > "$GIT_LOCAL" << 'GITLOCALEOF'
# Machine-specific git settings (not version controlled)
GITLOCALEOF
    fi

    # Append identity to git/local
    {
        echo "[user]"
        [ -n "${GIT_NAME:-}" ] && printf "    name = %s\n" "$GIT_NAME"
        [ -n "${GIT_EMAIL:-}" ] && printf "    email = %s\n" "$GIT_EMAIL"
    } >> "$GIT_LOCAL"
    echo "Git identity configured in $GIT_LOCAL."
fi

echo ""
echo "Dotfiles installation complete!"
echo "Please restart your terminal or run 'source ~/.zshrc' to apply changes."
