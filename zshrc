# Path to your oh-my-zsh installation.
export ZSH="/Users/xrisk/.oh-my-zsh"

plugins=(git z)

export ZSH_DISABLE_COMPFIX=true
source $ZSH/oh-my-zsh.sh


export MANPATH="/usr/local/man:$MANPATH"
export LANG=en_US.UTF-8
export EDITOR=vim

autoload -U promptinit; promptinit
prompt pure

export PATH=~/bin:/usr/local/sbin:$PATH

alias git=hub

source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

export PATH=$PATH:$(go env GOPATH)/bin

source ~/.secrets.sh

alias gs="git status"

export PATH="/usr/local/opt/postgresql@11/bin:$PATH"
export PATH=~/sketch:$PATH

eval "$(pyenv init -)"
source ~/.poetry/env
export BAT_STYLE="Solarized"

export PATH=~/bin:$PATH
export PATH=/Volumes/crosstool-ng/x-tools/x86_64-unknown-linux-gnu/bin:$PATH

export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'

source ~/notesystem.sh


# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
#
alias python=ipython
