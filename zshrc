#!/bin/env zsh
#
export ZPLUG_HOME=/usr/local/opt/zplug
source $ZPLUG_HOME/init.zsh

##############################################################################

zplug "b4b4r07/zplug"

zplug "mafredri/zsh-async"
zplug "sindresorhus/pure"

zplug "Tarrasch/zsh-autoenv"
zplug "zsh-users/zsh-syntax-highlighting"
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-autosuggestions"

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

export PATH="/usr/local/bin:/usr/bin:/usr/local/sbin:$PATH"

# set Command
alias cls="clear"
alias ll="ls -al"
alias vi="nvim"

export EDITOR=nvim

# set terminal basic color
export TERM="xterm-256color"
export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad

# set language
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# set pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

eval "$(pyenv init - zsh)"
if which pyenv-virtualenv-init > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi

# set nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm

# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
