# Create a new directory and enter it
function mkd() {
    mkdir -p "$@" && cd "$@"
}

# Change working directory to the top-most Finder window location (macOS only)
if [[ "$OSTYPE" == darwin* ]]; then
    function cdf() {
        cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')"
    }
fi

# Create a .tar.gz archive
function targz() {
    tar -zcvf "$1.tar.gz" "$1"
}

# Extract any archive
function extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Create a data URL from a file
function dataurl() {
    local mimeType=$(file -b --mime-type "$1")
    if [[ $mimeType == text/* ]]; then
        mimeType="${mimeType};charset=utf-8"
    fi
    echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
}

# Start a PHP server from a directory
if command -v php &>/dev/null; then
    function phpserver() {
        local port="${1:-4000}"
        local ip
        if [[ "$OSTYPE" == darwin* ]]; then
            ip=$(ipconfig getifaddr en0)
        else
            ip=$(hostname -I | awk '{print $1}')
        fi
        php -S "${ip}:${port}" &
        sleep 1
        if [[ "$OSTYPE" == darwin* ]]; then
            open "http://${ip}:${port}/"
        elif command -v xdg-open &>/dev/null; then
            xdg-open "http://${ip}:${port}/"
        else
            echo "Server running at http://${ip}:${port}/"
        fi
    }
fi

# Get gzipped file size
function gz() {
    echo "orig size    (bytes): "
    cat "$1" | wc -c
    echo "gzipped size (bytes): "
    gzip -c "$1" | wc -c
}

# Test if HTTP compression (RFC 2616 + SDCH) is enabled for a URL
function httpcompression() {
    curl -s -w "%{size_download}\n" -o /dev/null -H "Accept-Encoding: gzip,deflate,sdch" "$1"
}

# Start a new tmux session with a specific name
function tm() {
    tmux new -s "$1"
}

# Attach to an existing tmux session
function ta() {
    tmux attach -t "$1"
}

# List all tmux sessions
function tl() {
    tmux ls
}

# Kill a tmux session
function tk() {
    tmux kill-session -t "$1"
}

# Reload the shell configuration
function reload() {
    echo "Reloading shell configuration..."

    local alias_file="$HOME/.config/zsh/aliases.zsh"
    local -A new_aliases restore_map
    local aname aval new_val cur_def cur_val reply line

    if [[ -f "$alias_file" ]]; then
        # Determine which aliases the file will define (subshell inherits env for OS checks)
        while IFS= read -r line; do
            line="${line#-- }"         # strip -- prefix used for names starting with -
            aname="${line%%=*}"
            aval="${line#*=}"
            aval="${aval#\'}" ; aval="${aval%\'}"  # strip surrounding single quotes
            [[ -n "$aname" ]] && new_aliases[$aname]="$aval"
        done < <(zsh -c 'source "$1" 2>/dev/null; alias -L' -- "$alias_file" 2>/dev/null | sed 's/^alias //')

        # Prompt before overwriting any alias currently set to a different value
        for aname in "${(@k)new_aliases}"; do
            new_val="${new_aliases[$aname]}"
            cur_def=$(alias -- "$aname" 2>/dev/null)
            [[ -z "$cur_def" ]] && continue
            cur_val="${cur_def#*=}"
            cur_val="${cur_val#\'}" ; cur_val="${cur_val%\'}"
            [[ "$cur_val" == "$new_val" ]] && continue

            echo ""
            echo "  Alias '$aname' will change:"
            echo "    current: $cur_val"
            echo "    new:     $new_val"
            printf "  Overwrite? [y/N] "
            read -r reply
            echo
            [[ "$reply" != [yY] ]] && restore_map[$aname]="$cur_val"
        done

        # Unalias only the managed set (skip any the user declined to overwrite)
        for aname in "${(@k)new_aliases}"; do
            (( ${+restore_map[$aname]} )) && continue
            unalias -- "$aname" 2>/dev/null
        done
    fi

    # Source main config (which sources aliases.zsh, functions.zsh, local.zsh)
    source "$HOME/.config/zsh/.zshrc"

    # Restore any aliases the user chose not to overwrite
    for aname in "${(@k)restore_map}"; do
        alias -- "$aname=${restore_map[$aname]}"
    done

    # Re-initialize completion
    autoload -U compinit
    compinit

    # Re-initialize vcs_info
    autoload -Uz vcs_info

    echo "Shell configuration reloaded!"
}
