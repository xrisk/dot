# Path to your oh-my-zsh installation.
export ZSH="/Users/xrisk/.oh-my-zsh"

export ZSH_PYENV_LAZY_VIRTUALENV=true
plugins=(git z pyenv-lazy)

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

# source ~/.secrets.sh

alias gs="git status"

export PATH="/usr/local/opt/postgresql@11/bin:$PATH"
export PATH=~/sketch:$PATH

# eval "$(pyenv init -)"
# eval "$(pyenv virtualenv-init -)"
export BAT_STYLE="Solarized"

export PATH=~/bin:$PATH:~/.local/bin:$PATH

export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'

export CLASSPATH=".:/usr/local/Cellar/antlr/4.8_1/antlr-4.8-complete.jar:$CLASSPATH"
export PATH="/usr/local/opt/bison/bin:$PATH"
export PATH="/usr/local/opt/flex/bin:$PATH"
