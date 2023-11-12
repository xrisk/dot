set -gx HOMEBREW_PREFIX "/opt/homebrew";
set -gx HOMEBREW_CELLAR "/opt/homebrew/Cellar";
set -gx HOMEBREW_REPOSITORY "/opt/homebrew";
! set -q PATH; and set PATH ''; set -gx PATH "/opt/homebrew/bin" "/opt/homebrew/sbin" $PATH;
! set -q MANPATH; and set MANPATH ''; set -gx MANPATH "/opt/homebrew/share/man" $MANPATH;
! set -q INFOPATH; and set INFOPATH ''; set -gx INFOPATH "/opt/homebrew/share/info" $INFOPATH;

set -gx pure_show_system_time true

set -x SSH_AUTH_SOCK /Users/xrisk/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh

abbr --add vim nvim
abbr --add gc git commit -v
abbr --add gs git status
abbr --add ga git add
