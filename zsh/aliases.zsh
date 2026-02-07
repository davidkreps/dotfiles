# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# List directory contents
alias l='ls -lah'
alias la='ls -lAh'
alias ll='ls -lh'
alias lsa='ls -lah'
if [[ "$OSTYPE" == darwin* ]]; then
    alias ls='ls -G'
else
    alias ls='ls --color=auto'
fi

# Git
alias g='git'
alias gst='git status'
alias gd='git diff'
alias gdc='git diff --cached'
alias gl='git pull'
alias gp='git push'
alias gc='git commit -v'
alias gca='git commit -v -a'
alias gco='git checkout'
alias gb='git branch'
alias ga='git add'
alias gaa='git add --all'

# System
alias df='df -h'
alias du='du -h'
if [[ "$OSTYPE" != darwin* ]]; then
    alias free='free -m'
fi
alias more='less'
alias psg='ps aux | grep -v grep | grep -i'

# Safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Editor
alias v='vim'
alias nv='nvim'

# Docker
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dim='docker images'

# Kubernetes
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kl='kubectl logs'

# Python
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'

# Network
alias myip='curl -s https://ipinfo.io/ip'
if [[ "$OSTYPE" == darwin* ]]; then
    alias localip='ipconfig getifaddr en0'
else
    alias localip="hostname -I | awk '{print \$1}'"
fi
if [[ "$OSTYPE" == darwin* ]]; then
    alias ports='netstat -an -ptcp'
else
    alias ports='netstat -tulanp'
fi

# Misc
alias c='clear'
alias h='history'
alias j='jobs -l'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%T"'
alias nowtime=now
alias nowdate='date +"%d-%m-%Y"' 

# Claude
alias claude="$HOME/.claude/local/claude"
