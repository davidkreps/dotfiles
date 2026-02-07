# Enable colors
autoload -U colors && colors

# History settings
HISTFILE=~/.config/zsh/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt share_history
setopt hist_ignore_all_dups
setopt hist_ignore_space

# Basic auto/tab complete
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)		# Include hidden files

# vi mode
bindkey -v
export KEYTIMEOUT=1

# Use vim keys in tab complete menu
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

# Change cursor shape for different vi modes
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # Use beam shape cursor on startup
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt

# Edit line in vim with ctrl-e
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line

# Load configuration files
echo "Loading shell configuration..."

# Source prompt configuration
if [ -f "$HOME/.config/zsh/prompt.zsh" ]; then
    echo "Loading prompt configuration..."
    source "$HOME/.config/zsh/prompt.zsh"
else
    echo "Warning: prompt.zsh not found"
fi

# Load aliases if they exist
if [ -f "$HOME/.config/zsh/aliases.zsh" ]; then
    echo "Loading aliases..."
    source "$HOME/.config/zsh/aliases.zsh"
else
    echo "Warning: aliases.zsh not found"
fi

# Load functions if they exist
if [ -f "$HOME/.config/zsh/functions.zsh" ]; then
    echo "Loading functions..."
    source "$HOME/.config/zsh/functions.zsh"
else
    echo "Warning: functions.zsh not found"
fi

# Load local configuration if it exists
if [ -f "$HOME/.config/zsh/local.zsh" ]; then
    echo "Loading local configuration..."
    source "$HOME/.config/zsh/local.zsh"
else
    echo "Info: local.zsh not found (this is normal for new installations)"
fi

# NVM and npm configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# npm configuration
export PATH="$HOME/.npm-global/bin:$PATH"

# Add VSCode to the path
export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"

echo "Shell configuration loaded!"
