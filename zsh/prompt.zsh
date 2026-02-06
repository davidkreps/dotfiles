#!/bin/zsh

# Enable prompt substitution and syntax highlighting
setopt prompt_subst

# =============================================
# Git Integration
# =============================================
# Load VCS info module
autoload -Uz vcs_info

# Configure Git integration
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true

# Git status indicators
# ● = Unstaged changes (red)
# ● = Staged changes (green)
zstyle ':vcs_info:*' unstagedstr ' %F{red}●%f'
zstyle ':vcs_info:*' stagedstr ' %F{green}●%f'

# Git branch format
zstyle ':vcs_info:git:*' formats ' %F{blue}%b%f%u%c'
zstyle ':vcs_info:git:*' actionformats ' %F{blue}%b%f%u%c %F{red}(%a)%f'

# =============================================
# Prompt Configuration
# =============================================
# Main prompt format:
# username@hostname:current_directory [git_branch] ❯
# Colors:
# - cyan: username
# - green: hostname
# - yellow: current directory
# - blue: git branch
# - red/green: prompt arrow (❯) based on last command status
PROMPT='%F{cyan}%n%f@%F{green}%m%f:%F{yellow}%~%f${vcs_info_msg_0_} %(?.%F{green}❯%f.%F{red}❯%f) '

# =============================================
# Right Prompt Configuration
# =============================================
# Right prompt shows:
# - Exit status (if non-zero)
# - Current time
function precmd() {
    local exit_code=$?
    vcs_info
    if [[ $exit_code -eq 0 ]]; then
        RPROMPT='%F{blue}%T%f'
    else
        RPROMPT="%F{red}${exit_code} %F{blue}%T%f"
    fi
} 