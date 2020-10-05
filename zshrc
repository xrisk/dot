#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# https://github.com/davidparsson/zsh-pyenv-lazy

export PYENV_ROOT="${PYENV_ROOT:=${HOME}/.pyenv}"
if ! type pyenv > /dev/null && [ -f "${PYENV_ROOT}/bin/pyenv" ]; then
    export PATH="${PYENV_ROOT}/bin:${PATH}"
fi


ZSH_PYENV_LAZY_VIRTUALENV=true
# Lazy load pyenv
if type pyenv > /dev/null; then
    export PATH="${PYENV_ROOT}/bin:${PYENV_ROOT}/shims:${PATH}"
    function pyenv() {
        unset -f pyenv
        eval "$(command pyenv init -)"
        if [[ -n "${ZSH_PYENV_LAZY_VIRTUALENV}" ]]; then
            eval "$(command pyenv virtualenv-init -)"
        fi
        pyenv $@
    }
fi

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey -M "emacs" "$key_info[Up]" up-line-or-beginning-search
bindkey -M "emacs" "$key_info[Down]" down-line-or-beginning-search

source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

alias gs="git status"
alias gp="git push"
alias ga="git add"
alias gl"git pull"
alias gc="git commit"
alias gd="git diff"

export PATH=~/bin:$PATH:~/.local/bin:$PATH

export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'

export CLASSPATH=".:/usr/local/Cellar/antlr/4.8_1/antlr-4.8-complete.jar:$CLASSPATH"
export PATH="/usr/local/opt/bison/bin:$PATH"
export PATH="/usr/local/opt/flex/bin:$PATH"

export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'

export CLASSPATH=".:/usr/local/Cellar/antlr/4.8_1/antlr-4.8-complete.jar:$CLASSPATH"
export PATH="/usr/local/opt/bison/bin:$PATH"
export PATH="/usr/local/opt/flex/bin:$PATH"

unsetopt correct
unsetopt correctall
DISABLE_CORRECTION="true"

export EDITOR="vim"
export GIT_EDITOR=$EDITOR

source /usr/local/bin/z.sh

alias vim=nvim

alias deactivate="pyenv deactivate"
export LESS=-r
