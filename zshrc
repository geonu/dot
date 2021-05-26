# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#!/bin/env zsh

export ZPLUG_HOME=/usr/local/opt/zplug
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
eval "$(/opt/homebrew/bin/brew shellenv)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

