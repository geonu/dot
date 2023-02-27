# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#!/bin/env zsh

export ZPLUG_HOME=~/.zplug
source $ZPLUG_HOME/init.zsh

##############################################################################

zplug "b4b4r07/zplug"

# theme
zplug "romkatv/powerlevel10k", as:theme, depth:1

zplug "mafredri/zsh-async"
zplug "Tarrasch/zsh-autoenv"
zplug "zsh-users/zsh-syntax-highlighting"
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-autosuggestions"

# shortcut
zplug "plugins/docker",   from:oh-my-zsh
zplug "plugins/docker-compose",   from:oh-my-zsh
zplug "plugins/git",   from:oh-my-zsh, if:"(( $+commands[git] ))"

# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# Then, source plugins and add commands to $PATH
zplug load --verbose
##############################################################################

# set for tmux-spotify
export MUSIC_APP="Music"

# set Command
alias cls="clear"
alias ll="exa -al"
alias vi="nvim"

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
alias fzf="fzf --preview 'bat --style=numbers --color=always {} | head -500'"

export EDITOR=nvim

# set terminal basic color
export TERM="xterm-256color"
export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad

# set language
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# set homebrew
#if [ -e /opt/homebrew ]; then
#    HOMEBREW_ROOT=/opt/homebrew
#else
#    HOMEBREW_ROOT=/usr/local
#fi
#  export HOMEBREW_ROOT
#eval $(${HOMEBREW_ROOT}/bin/brew shellenv)
# Installing x86, Apple Silicon not satisfied
#alias brew='arch -x86_64 /usr/local/bin/brew'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
# pyenv installing
export LDFLAGS="-L/usr/local/opt/zlib/lib -L/usr/local/opt/bzip2/lib"
export CPPFLAGS="-I/usr/local/opt/zlib/include -I/usr/local/opt/bzip2/include"

# set java
export PATH="/usr/local/opt/openjdk/bin:$PATH"

# set nvm
export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

source /Users/geonu/.docker/init-zsh.sh || true # Added by Docker Desktop
