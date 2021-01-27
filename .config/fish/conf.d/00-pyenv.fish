set -q PYENV_ROOT; or set -l PYENV_ROOT $HOME/.pyenv

set -gx PATH $PYENV_ROOT/shims $PATH
setenv PYENV_SHELL fish
