#!/bin/bash

# test.sh — Automated tests for the dotfiles project
# Run: ./test.sh
# Zero dependencies beyond bash and zsh.

set -u

REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PASS_COUNT=0
FAIL_COUNT=0

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    GREEN=''
    RED=''
    BOLD=''
    RESET=''
fi

# ─── Assertion helpers ────────────────────────────────────────────────

pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    printf "  ${GREEN}✓${RESET} %s\n" "$1"
}

fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf "  ${RED}✗${RESET} %s\n" "$1"
    [ -n "${2:-}" ] && printf "    %s\n" "$2"
}

assert_file_exists() {
    local file="$1" label="$2"
    if [ -f "$file" ]; then
        pass "$label"
    else
        fail "$label" "expected file: $file"
    fi
}

assert_dir_exists() {
    local dir="$1" label="$2"
    if [ -d "$dir" ]; then
        pass "$label"
    else
        fail "$label" "expected directory: $dir"
    fi
}

assert_symlink_to() {
    local link="$1" target="$2" label="$3"
    if [ -L "$link" ]; then
        local actual
        actual=$(readlink "$link")
        if [ "$actual" = "$target" ]; then
            pass "$label"
        else
            fail "$label" "symlink points to '$actual', expected '$target'"
        fi
    else
        fail "$label" "not a symlink: $link"
    fi
}

assert_not_symlink() {
    local file="$1" label="$2"
    if [ -f "$file" ] && [ ! -L "$file" ]; then
        pass "$label"
    elif [ -L "$file" ]; then
        fail "$label" "expected regular file but got symlink: $file"
    else
        fail "$label" "file does not exist: $file"
    fi
}

assert_eq() {
    local actual="$1" expected="$2" label="$3"
    if [ "$actual" = "$expected" ]; then
        pass "$label"
    else
        fail "$label" "got '$actual', expected '$expected'"
    fi
}

assert_contains() {
    local haystack="$1" needle="$2" label="$3"
    if echo "$haystack" | grep -qF "$needle"; then
        pass "$label"
    else
        fail "$label" "output did not contain '$needle'"
    fi
}

assert_empty() {
    local value="$1" label="$2"
    if [ -z "$value" ]; then
        pass "$label"
    else
        fail "$label" "expected empty, got: $value"
    fi
}

# ─── Setup / Teardown ────────────────────────────────────────────────

TEMP_HOME=""

setup() {
    TEMP_HOME=$(mktemp -d)
    export HOME="$TEMP_HOME"
    export XDG_CONFIG_HOME="$HOME/.config"
    # Redirect git --global writes to a file in temp HOME so they don't
    # flow through the symlinked git/config back into the repo.
    export GIT_CONFIG_GLOBAL="$TEMP_HOME/.gitconfig"
    # Provide git identity via stdin so install.sh doesn't block
    printf 'Test User\ntest@example.com\n' | bash "$REPO_DIR/install.sh" > /dev/null 2>&1
}

teardown() {
    if [ -n "$TEMP_HOME" ] && [ -d "$TEMP_HOME" ]; then
        rm -rf "$TEMP_HOME"
    fi
}

trap teardown EXIT

# ─── Test groups ──────────────────────────────────────────────────────

test_installation() {
    printf "\n${BOLD}Installation tests${RESET}\n"

    # Directory structure
    assert_dir_exists "$HOME/.config/zsh" "~/.config/zsh/ directory exists"
    assert_dir_exists "$HOME/.config/git" "~/.config/git/ directory exists"

    # Zsh symlinks
    assert_symlink_to "$HOME/.config/zsh/.zshrc"       "$REPO_DIR/zsh/.zshrc"       "zsh/.zshrc symlink"
    assert_symlink_to "$HOME/.config/zsh/prompt.zsh"    "$REPO_DIR/zsh/prompt.zsh"    "zsh/prompt.zsh symlink"
    assert_symlink_to "$HOME/.config/zsh/aliases.zsh"   "$REPO_DIR/zsh/aliases.zsh"   "zsh/aliases.zsh symlink"
    assert_symlink_to "$HOME/.config/zsh/functions.zsh" "$REPO_DIR/zsh/functions.zsh" "zsh/functions.zsh symlink"

    # Git symlinks
    assert_symlink_to "$HOME/.config/git/config" "$REPO_DIR/git/config" "git/config symlink"
    assert_symlink_to "$HOME/.config/git/ignore" "$REPO_DIR/git/ignore" "git/ignore symlink"

    # Compatibility symlink
    assert_symlink_to "$HOME/.zshrc" "$HOME/.config/zsh/.zshrc" "~/.zshrc compatibility symlink"

    # local.zsh is a real file, not a symlink
    assert_not_symlink "$HOME/.config/zsh/local.zsh" "local.zsh is a regular file"

    # Git identity was configured
    local git_name
    git_name=$(git config --global user.name 2>/dev/null || true)
    assert_eq "$git_name" "Test User" "git user.name was configured"

    # Idempotency — run install.sh again
    echo "# custom local setting" >> "$HOME/.config/zsh/local.zsh"
    printf 'Test User\ntest@example.com\n' | bash "$REPO_DIR/install.sh" > /dev/null 2>&1

    # local.zsh content preserved
    local local_content
    local_content=$(cat "$HOME/.config/zsh/local.zsh")
    assert_contains "$local_content" "# custom local setting" "idempotency: local.zsh content preserved"

    # Symlinks still correct after re-run
    assert_symlink_to "$HOME/.config/zsh/.zshrc" "$REPO_DIR/zsh/.zshrc" "idempotency: symlinks still correct"
}

test_shell_config() {
    printf "\n${BOLD}Shell config tests${RESET}\n"

    # Source .zshrc in non-interactive zsh
    local zsh_stderr zsh_stdout
    zsh_stdout=$(zsh -c 'source "$HOME/.config/zsh/.zshrc"' 2>/dev/null)
    local zsh_exit=$?
    zsh_stderr=$(zsh -c 'source "$HOME/.config/zsh/.zshrc"' 2>&1 >/dev/null)

    assert_eq "$zsh_exit" "0" ".zshrc sources without error"
    # Filter terminal escape sequences (e.g. cursor shape \e[5 q) — only flag human-readable text
    local readable_output
    readable_output=$(printf '%s' "$zsh_stdout" | sed $'s/\x1b\[[0-9;]* q//g; s/\x1b\[[0-9;]*[a-zA-Z]//g' | tr -d '[:cntrl:]')
    assert_empty "$readable_output" "no human-readable stdout during non-interactive init"
    assert_empty "$zsh_stderr" "no stderr during non-interactive init"

    # Check key aliases exist
    for alias_name in g gst ls rm ll; do
        local alias_check
        alias_check=$(zsh -c 'source "$HOME/.config/zsh/.zshrc"; alias '"$alias_name" 2>&1)
        if [ $? -eq 0 ]; then
            pass "alias '$alias_name' is defined"
        else
            fail "alias '$alias_name' is defined" "alias not found"
        fi
    done

    # Check key functions exist
    for func_name in mkd extract reload targz; do
        local func_check
        func_check=$(zsh -c 'source "$HOME/.config/zsh/.zshrc"; whence -w '"$func_name" 2>&1)
        if echo "$func_check" | grep -q "function"; then
            pass "function '$func_name' is defined"
        else
            fail "function '$func_name' is defined" "got: $func_check"
        fi
    done
}

test_git_config() {
    printf "\n${BOLD}Git config tests${RESET}\n"

    # git config parses without error
    git config --file "$REPO_DIR/git/config" --list > /dev/null 2>&1
    assert_eq "$?" "0" "git/config parses without error"

    # Key aliases present
    for alias_name in lg s last unstage; do
        local value
        value=$(git config --file "$REPO_DIR/git/config" "alias.$alias_name" 2>/dev/null || true)
        if [ -n "$value" ]; then
            pass "git alias '$alias_name' is defined"
        else
            fail "git alias '$alias_name' is defined" "alias not found in git/config"
        fi
    done
}

test_file_hygiene() {
    printf "\n${BOLD}File hygiene tests${RESET}\n"

    # All tracked shell/config files end with a trailing newline
    local bad_newline=""
    while IFS= read -r file; do
        if [ -f "$file" ] && [ -s "$file" ]; then
            # Check if last byte is a newline
            local last_byte
            last_byte=$(tail -c 1 "$file" | xxd -p)
            if [ "$last_byte" != "0a" ] && [ -n "$last_byte" ]; then
                bad_newline="$bad_newline $file"
            fi
        fi
    done < <(git -C "$REPO_DIR" ls-files -- '*.zsh' '*.sh' 'git/config' 'git/ignore')

    if [ -z "$bad_newline" ]; then
        pass "all tracked shell/config files end with trailing newline"
    else
        fail "all tracked shell/config files end with trailing newline" "missing in:$bad_newline"
    fi

    # No hardcoded /Users/ paths (excluding test.sh itself and CLAUDE.md)
    local hardcoded
    hardcoded=$(git -C "$REPO_DIR" ls-files | grep -v '^test\.sh$' | grep -v '^CLAUDE\.md$' | while IFS= read -r file; do
        if [ -f "$REPO_DIR/$file" ]; then
            grep -n '/Users/' "$REPO_DIR/$file" 2>/dev/null && echo "  ^ in $file"
        fi
    done)

    if [ -z "$hardcoded" ]; then
        pass "no hardcoded /Users/ paths in tracked files"
    else
        fail "no hardcoded /Users/ paths in tracked files" "$hardcoded"
    fi
}

# ─── Run ──────────────────────────────────────────────────────────────

printf "${BOLD}Running dotfiles tests...${RESET}\n"

setup
test_installation
test_shell_config
test_git_config
test_file_hygiene

printf "\n${BOLD}Results:${RESET} ${GREEN}${PASS_COUNT} passed${RESET}, ${RED}${FAIL_COUNT} failed${RESET}\n"

[ "$FAIL_COUNT" -eq 0 ] && exit 0 || exit 1
