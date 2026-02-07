# CLAUDE.md

Personal dotfiles repo. XDG-compliant configs installed via symlinks to `~/.config/`.

## Core philosophy

- **Zero-friction setup**: Clone and run `install.sh` — nothing else required
- **Portable**: Must work on both macOS and Linux with no manual adjustment
- **Safe**: No dependencies that could compromise the machine; no silent data loss
- **Self-contained**: No external downloads, curled scripts, or package installs during setup
- **Graceful degradation**: Missing tools should be silently skipped, never cause errors

## Where things go

- **Aliases** → `zsh/aliases.zsh`
- **Functions** → `zsh/functions.zsh`
- **Prompt** → `zsh/prompt.zsh`
- **Machine-specific settings** → `zsh/local.zsh` is a template; the installed copy at `~/.config/zsh/local.zsh` is not tracked
- **Git aliases** → `git/config` under `[alias]`, use short memorable names
- **New tool configs** → create `tool-name/` directory, add symlinks to `install.sh`

## Rules

- Use `$HOME` instead of hardcoded paths — configs must be portable across machines
- Never commit credentials, API keys, or secrets — use `local.zsh` for those
- Edit source files in this repo, not the symlinked files in `~/.config/`
- When adding new config files, update `install.sh` with the corresponding symlink
- All files must end with a trailing newline
- `install.sh` must remain idempotent (safe to run multiple times)
- Follow existing patterns and conventions in each file
- Guard platform-specific code with OS detection (`[[ "$OSTYPE" == darwin* ]]`)
- Guard tool-specific config with existence checks (`command -v tool &>/dev/null`)
- Never produce stdout during shell init — it breaks scp, rsync, and IDE integrations
- Aliases and functions for optional tools must not error when the tool is missing
- install.sh should prompt for any required user-specific values (e.g., git identity)
- Beware symlink write-through — tools writing to `~/.config/git/config` modify the repo source. Use `GIT_CONFIG_GLOBAL` or similar overrides in scripts that set config in a temp environment.

## Testing

Run `./test.sh` to validate installation, shell config, git config, and file hygiene. Add tests when adding new symlinks or config files.
