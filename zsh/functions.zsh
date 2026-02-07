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
    
    # Source all configuration files
    source "$HOME/.config/zsh/.zshrc"
    [ -f "$HOME/.config/zsh/aliases.zsh" ] && source "$HOME/.config/zsh/aliases.zsh"
    [ -f "$HOME/.config/zsh/functions.zsh" ] && source "$HOME/.config/zsh/functions.zsh"
    [ -f "$HOME/.config/zsh/local.zsh" ] && source "$HOME/.config/zsh/local.zsh"
    
    # Re-initialize completion
    autoload -U compinit
    compinit
    
    # Re-initialize vcs_info
    autoload -Uz vcs_info
    
    echo "Shell configuration reloaded!"
}
