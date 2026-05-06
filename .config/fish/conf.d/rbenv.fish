set -gx RBENV_ROOT $XDG_DATA_HOME/rbenv
set -gx RBENV_SHELL fish
fish_add_path $RBENV_ROOT/shims
# command rbenv rehash 2>/dev/null
