[[ $- != *i* ]] && return

# ── Editor ────────────────────────────────────────────────────────
export EDITOR='nvim'
export VISUAL='nvim'
alias vim='nvim'
alias vi='nvim'

# ── History ───────────────────────────────────────────────────────
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth
shopt -s histappend

# ── Completion ────────────────────────────────────────────────────
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# ── Prompt (fallback, starship takes over if installed) ──────────
blue='\[\e[38;2;23;147;209m\]'
fg='\[\e[38;2;229;225;231m\]'
dim='\[\e[38;2;145;143;154m\]'
reset='\[\e[0m\]'
PS1="${blue}\u${fg}@${blue}\h ${dim}\W${fg}\$ ${reset}"

# ── Starship prompt ───────────────────────────────────────────────
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi

# ── Direnv + Zoxide ───────────────────────────────────────────────
if command -v direnv &>/dev/null; then
    eval "$(direnv hook bash)"
fi
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi

# ── Caelestia terminal colors ─────────────────────────────────────
[ -f ~/.local/state/caelestia/sequences.txt ] && cat ~/.local/state/caelestia/sequences.txt

# ── ls / eza ──────────────────────────────────────────────────────
if command -v eza &>/dev/null; then
    alias ls='eza --icons --group-directories-first'
else
    alias ls='ls --color=auto'
fi
alias ll='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias mkdir='mkdir -p'
alias df='df -h'
alias free='free -h'
alias du='du -h'
alias ip='ip -c'
alias ping='ping -c 4'

# ── Git ───────────────────────────────────────────────────────────
alias lg='lazygit'
alias gd='git diff'
alias ga='git add .'
alias gc='git commit -am'
alias gl='git log'
alias gs='git status'
alias gst='git stash'
alias gsp='git stash pop'
alias gp='git push'
alias gpl='git pull'
alias gsw='git switch'
alias gsm='git switch main'
alias gb='git branch'
alias gbd='git branch -d'
alias gco='git checkout'
alias gsh='git show'

# ── Pacman ────────────────────────────────────────────────────────
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rns'
alias search='pacman -Ss'
alias cleanup='sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null || true'

# ── Man pages with bat ────────────────────────────────────────────
export MANROFFOPT='-c'
if command -v bat &>/dev/null; then
    export MANPAGER='sh -c "col -b | bat -l man -p"'
fi

# ── Fastfetch with dynamic sizing ─────────────────────────────────
fastfetch() {
    local cols=$(tput cols 2>/dev/null || echo 80)
    local width=$((cols / 3))
    width=$((width > 50 ? 50 : width))
    width=$((width < 15 ? 15 : width))
    command fastfetch --logo-width "$width" "$@"
}

# ── nvm ───────────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
