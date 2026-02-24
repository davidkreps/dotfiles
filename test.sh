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
REPO_SNAPSHOT=""

# Repo files that get symlinked into ~/.config (write-through targets)
SYMLINK_TARGETS=(
    "zsh/.zshrc"
    "zsh/prompt.zsh"
    "zsh/aliases.zsh"
    "zsh/functions.zsh"
    "git/config"
    "git/ignore"
)

snapshot_repo_files() {
    local snapshot_file="$1"
    local f
    for f in "${SYMLINK_TARGETS[@]}"; do
        shasum "$REPO_DIR/$f"
    done > "$snapshot_file"
}

assert_repo_unchanged() {
    local before="$1" label="$2"
    local after
    after=$(mktemp)
    local f
    for f in "${SYMLINK_TARGETS[@]}"; do
        shasum "$REPO_DIR/$f"
    done > "$after"
    if diff -q "$before" "$after" > /dev/null 2>&1; then
        pass "$label"
    else
        local changed
        changed=$(diff "$before" "$after" | grep '^>' | sed 's/.*  /  /')
        fail "$label" "repo files modified:$changed"
    fi
    rm -f "$after"
}

setup() {
    TEMP_HOME=$(mktemp -d)
    REPO_SNAPSHOT=$(mktemp)
    snapshot_repo_files "$REPO_SNAPSHOT"
    export HOME="$TEMP_HOME"
    export XDG_CONFIG_HOME="$HOME/.config"
    # Provide git identity via stdin so install.sh doesn't block
    printf 'Test User\ntest@example.com\n' | bash "$REPO_DIR/install.sh" > /dev/null 2>&1
}

teardown() {
    if [ -n "$TEMP_HOME" ] && [ -d "$TEMP_HOME" ]; then
        rm -rf "$TEMP_HOME"
    fi
    [ -n "$REPO_SNAPSHOT" ] && rm -f "$REPO_SNAPSHOT"
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

    # git/local is a real file, not a symlink
    assert_not_symlink "$HOME/.config/git/local" "git/local is a regular file"

    # No symlink write-through after initial install
    assert_repo_unchanged "$REPO_SNAPSHOT" "install.sh did not modify repo source files"

    # Git identity was written to git/local
    local git_name
    git_name=$(git config --file "$HOME/.config/git/local" user.name 2>/dev/null || true)
    assert_eq "$git_name" "Test User" "git user.name was configured in git/local"

    # Idempotency — run install.sh again
    echo "# custom local setting" >> "$HOME/.config/zsh/local.zsh"
    echo "# custom git setting" >> "$HOME/.config/git/local"
    bash "$REPO_DIR/install.sh" > /dev/null 2>&1

    # local.zsh content preserved
    local local_content
    local_content=$(cat "$HOME/.config/zsh/local.zsh")
    assert_contains "$local_content" "# custom local setting" "idempotency: local.zsh content preserved"

    # git/local content preserved and identity not duplicated
    local git_local_content
    git_local_content=$(cat "$HOME/.config/git/local")
    assert_contains "$git_local_content" "# custom git setting" "idempotency: git/local content preserved"

    # No symlink write-through after idempotency re-run
    assert_repo_unchanged "$REPO_SNAPSHOT" "idempotency: no repo source files modified"

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

test_reload() {
    printf "\n${BOLD}reload() tests${RESET}\n"

    # Basic smoke test: reload exits cleanly with no conflicts
    local exit_code output
    output=$(HOME="$TEMP_HOME" zsh -c '
        source "$HOME/.config/zsh/.zshrc"
        reload
    ' 2>&1)
    exit_code=$?
    assert_eq "$exit_code" "0" "reload() exits successfully with no conflicts"
    assert_contains "$output" "Shell configuration reloaded!" "reload() prints completion message"

    # Aliases defined in aliases.zsh are set after reload
    local alias_val
    alias_val=$(HOME="$TEMP_HOME" zsh -c '
        source "$HOME/.config/zsh/.zshrc"
        reload > /dev/null 2>&1
        alias ll 2>/dev/null
    ' 2>/dev/null)
    assert_contains "$alias_val" "ll=" "reload() restores managed aliases"

    # Unmanaged aliases (manually set, not in aliases.zsh) survive reload
    alias_val=$(HOME="$TEMP_HOME" zsh -c '
        source "$HOME/.config/zsh/.zshrc"
        alias my_custom_alias="echo test-value"
        reload > /dev/null 2>&1
        alias my_custom_alias 2>/dev/null
    ' 2>/dev/null)
    assert_contains "$alias_val" "test-value" "reload() preserves unmanaged aliases"

    # No prompt when alias value is unchanged
    local prompt_output
    prompt_output=$(HOME="$TEMP_HOME" zsh -c '
        source "$HOME/.config/zsh/.zshrc"
        reload 2>&1
    ')
    if echo "$prompt_output" | grep -q "will change"; then
        fail "reload() does not prompt for unchanged aliases" "got unexpected prompt: $prompt_output"
    else
        pass "reload() does not prompt for unchanged aliases"
    fi

    # Prompt shows current and new values when alias will change
    local conflict_output
    conflict_output=$(printf 'n\n' | HOME="$TEMP_HOME" zsh -c '
        source "$HOME/.config/zsh/.zshrc"
        alias ll="old-custom-value"
        reload 2>&1
    ' 2>&1)
    assert_contains "$conflict_output" "current:" "reload() shows current value in conflict prompt"
    assert_contains "$conflict_output" "new:" "reload() shows new value in conflict prompt"
    assert_contains "$conflict_output" "old-custom-value" "reload() includes old alias in prompt"

    # User declines overwrite: alias retains its current value
    local retained_val
    retained_val=$(printf 'n\n' | HOME="$TEMP_HOME" zsh -c '
        source "$HOME/.config/zsh/.zshrc"
        alias ll="my-preserved-value"
        reload > /dev/null 2>&1
        alias ll 2>/dev/null
    ' 2>/dev/null)
    assert_contains "$retained_val" "my-preserved-value" "reload() retains alias when user declines overwrite"

    # User accepts overwrite: alias is updated to the config value
    local updated_val
    updated_val=$(printf 'y\n' | HOME="$TEMP_HOME" zsh -c '
        source "$HOME/.config/zsh/.zshrc"
        alias ll="my-old-value"
        reload > /dev/null 2>&1
        alias ll 2>/dev/null
    ' 2>/dev/null)
    if echo "$updated_val" | grep -q "my-old-value"; then
        fail "reload() updates alias when user accepts overwrite" "old value still set: $updated_val"
    else
        pass "reload() updates alias when user accepts overwrite"
    fi
}

# ─── Run ──────────────────────────────────────────────────────────────

printf "${BOLD}Running dotfiles tests...${RESET}\n"

setup
test_installation
test_shell_config
test_git_config
test_file_hygiene
test_reload

printf "\n${BOLD}Results:${RESET} ${GREEN}${PASS_COUNT} passed${RESET}, ${RED}${FAIL_COUNT} failed${RESET}\n"

[ "$FAIL_COUNT" -eq 0 ] && exit 0 || exit 1
