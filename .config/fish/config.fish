set -gx LANG en_US.UTF-8
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
abbr --add glog git log --pretty --oneline --graph
abbr --add gco git checkout
abbr --add gp git push
abbr --add gl git pull
abbr --add gd git diff

set -gx EDITOR nvim

fish_add_path $HOME/bin
fish_add_path "/Users/xrisk/.local/bin"

# Kanagawa Fish shell theme
# A template was taken and modified from Tokyonight:
# https://github.com/folke/tokyonight.nvim/blob/main/extras/fish_tokyonight_night.fish
set -l foreground DCD7BA normal
set -l selection 2D4F67 brcyan
set -l comment 727169 brblack
set -l red C34043 red
set -l orange FF9E64 brred
set -l yellow C0A36E yellow
set -l green 76946A green
set -l purple 957FB8 magenta
set -l cyan 7AA89F cyan
set -l pink D27E99 brmagenta

# Syntax Highlighting Colors
set -g fish_color_normal $foreground
set -g fish_color_command $cyan
set -g fish_color_keyword $pink
set -g fish_color_quote $yellow
set -g fish_color_redirection $foreground
set -g fish_color_end $orange
set -g fish_color_error $red
set -g fish_color_param $purple
set -g fish_color_comment $comment
set -g fish_color_selection --background=$selection
set -g fish_color_search_match --background=$selection
set -g fish_color_operator $green
set -g fish_color_escape $pink
set -g fish_color_autosuggestion $comment

# Completion Pager Colors
set -g fish_pager_color_progress $comment
set -g fish_pager_color_prefix $cyan
set -g fish_pager_color_completion $foreground
set -g fish_pager_color_description $comment





set -q GHCUP_INSTALL_BASE_PREFIX[1]; or set GHCUP_INSTALL_BASE_PREFIX $HOME ; set -gx PATH $HOME/.cabal/bin $PATH /Users/xrisk/.ghcup/bin # ghcup-env

abbr --add k kubectl

set fish_cursor_default block
set fish_cursor_insert block
set fish_cursor_replace_one block
set fish_cursor_visual block

set -g fish_greeting

# set -gx NVIM_APPNAME astronvim_v6

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /Users/xrisk/.lmstudio/bin
# End of LM Studio CLI section


# Added by Antigravity
fish_add_path /Users/xrisk/.antigravity/antigravity/bin

# set -gx ANTHROPIC_BASE_URL http://localhost:1234



# export DYLD_LIBRARY_PATH="$(brew --prefix ffmpeg)/lib:$DYLD_LIBRARY_PATH"

# set -gx DYLD_LIBRARY_PATH /opt/homebrew/opt/ffmpeg/lib $DYLD_LIBRARY_PATH

set -gx DYLD_LIBRARY_PATH /opt/homebrew/opt/ffmpeg@7/lib

set -gx UV_TORCH_BACKEND auto

fish_add_path /opt/homebrew/opt/ffmpeg@7/bin
set -gx LDFLAGS "-L/opt/homebrew/opt/ffmpeg@7/lib"
set -gx CPPFLAGS "-I/opt/homebrew/opt/ffmpeg@7/include"
set -gx PKG_CONFIG_PATH "/opt/homebrew/opt/ffmpeg@7/lib/pkgconfig"

fish_add_path ~/bin

zoxide init fish | source
set -x LESS "-R --mouse --wheel-lines=3"

# Load secrets (gitignored — put HF_TOKEN, API keys, etc. here)
set -l secrets_file $XDG_CONFIG_HOME/fish/conf.d/secrets.fish
if test -f $secrets_file
    source $secrets_file
end
