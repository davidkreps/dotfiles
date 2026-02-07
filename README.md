# Dotfiles

Personal dotfiles. XDG-compliant configs installed via symlinks to `~/.config/`.

## Installation

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer will:
- Create `~/.config/zsh/` and `~/.config/git/` directories
- Symlink config files from the repo into `~/.config/`
- Create a `~/.zshrc` compatibility symlink
- Create `~/.config/zsh/local.zsh` for machine-specific settings (if it doesn't exist)
- Prompt for your git identity (name and email) if not already configured

Safe to run multiple times — existing `local.zsh` content is preserved.

## Structure

- `zsh/` — Zsh configuration (aliases, functions, prompt, vi mode)
- `git/` — Git configuration (aliases, colors, global ignore)
- `install.sh` — Idempotent installation script
- `test.sh` — Automated test suite

## Testing

```bash
./test.sh
```

Validates installation, shell config, git config, and file hygiene in an isolated temp environment.

## License

MIT
