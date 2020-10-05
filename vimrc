call plug#begin()
Plug 'tpope/vim-sensible'
Plug 'psf/black'
Plug 'scrooloose/nerdtree'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'lervag/vimtex'
Plug 'tpope/vim-sleuth'
Plug 'lifepillar/vim-solarized8'
Plug 'prettier/vim-prettier', {'do': 'npm install'}
Plug 'Valloric/MatchTagAlways'
Plug 'tpope/vim-commentary'
" Plug 'tpope/vim-fugitive'
" Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() } }
" Plug 'wlangstroth/vim-racket'
" Plug 'davidhalter/jedi-vim'
" Plug 'xavierchow/vim-swagger-preview'
Plug 'ycm-core/YouCompleteMe'
" Plug 'nvie/vim-flake8'
Plug 'rust-lang/rust.vim'
" Plug 'https://github.com/tpope/vim-liquid'
" Plug 'vim-syntastic/syntastic'
" Plug 'https://github.com/wagnerf42/vim-clippy'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
" Plug 'gruvbox-community/gruvbox'
Plug 'https://github.com/Yggdroot/indentLine'
" Plug 'neovimhaskell/haskell-vim'
" Plug 'alx741/vim-hindent'
" Plug 'leafgarland/typescript-vim'
" Plug 'arcticicestudio/nord-vim'
" Plug 'maxmellon/vim-jsx-pretty'
" Plug 'SirVer/ultisnips'
" Plug 'honza/vim-snippets'
call plug#end()

" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
"
let g:UltiSnipsExpandTrigger="kj"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

" If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit="vertical"

set mouse=a

set expandtab
set shiftwidth=4
set softtabstop=4

set termguicolors
set background=light
colorscheme solarized8
set number
syntax on

" Protect changes between writes. Default values of
" updatecount (200 keystrokes) and updatetime
" (4 seconds) are fine
set swapfile
set directory=~/.vim/swap//

" protect against crash-during-write
set writebackup
" but do not persist backup after successful write
" set nobackup
" use rename-and-write-new method whenever safe
set backupcopy=auto
" patch required to honor double slash at end
if has("patch-8.1.0251")
	" consolidate the writebackups -- not a big
	" deal either way, since they usually get deleted
	set backupdir=~/.vim/backup//
end

" persist the undo tree for each file
set undofile
set undodir=~/.vim/undo//

set autoread

" autocmd BufWritePost *.c silent ! clang-format -i -style=LLVM "%:p"
autocmd BufWritePost *.cpp silent ! clang-format -i -style=LLVM "%:p"
autocmd BufWritePost *.h silent ! clang-format -i -style=LLVM "%:p"

autocmd BufWritePre *.py execute ":Black"

set clipboard=unnamedplus

let g:airline_theme='solarized'
let g:vimtex_compiler_method = 'latexmk'
" let g:vimtex_compiler_latexmk = {
"   \ 'options': [
"   \ '-xelaggtex', 
"   \ ]
"   \}

let g:vimtex_view_method = 'skim'
let g:vimtex_quickfix_open_on_warning = 0
let g:clang_library_path = '/Library/Developer/CommandLineTools/usr/lib/libclang.dylib'

nnoremap <leader>m :silent make\|redraw!\|cw<CR>

noremap <silent> k gk
noremap <silent> j gj
noremap <silent> 0 g0
noremap <silent> $ g$

" let g:prettier#autoformat = 0
autocmd BufWritePre *.js,*.jsx,*.mjs,*.ts,*.tsx,*.css,*.less,*.scss,*.json,*.graphql,*.vue,*.yaml,*.html,*.md Prettier

" autocmd BufWritePost *.py call flake8#Flake8()

" set relativenumber

nnoremap <C-b> :NERDTreeToggle<CR>
nnoremap <leader>r ! racket "%:p"<CR>

set title

let g:black_linelength = 79

" autocmd BufWritePost *.sql silent ! pg_format "%:p" -u 1 -o "%:p"
let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|git'
" let g:ycm_clangd_binary_path = "/Users/xrisk/etc/clangd"
let g:ycm_confirm_extra_conf = 0
set guifont=SFMono-Regular:h13

aug QFClose
  au!
  au WinEnter * if winnr('$') == 1 && &buftype == "quickfix"|q|endif
aug END

let g:rustfmt_autosave = 1
let g:ycm_autoclose_preview_window_after_completion = 1
" set statusline+=%#warningmsg#
" set statusline+=%{SyntasticStatuslineFlag()}
" set statusline+=%*

" let g:syntastic_always_populate_loc_list = 1
" let g:syntastic_auto_loc_list = 1
" let g:syntastic_check_on_open = 1
" let g:syntastic_check_on_wq = 0
" let g:syntastic_aggregate_errors = 1

autocmd FileType rust let g:ycm_show_diagnostics_ui = 0

" let g:syntastic_rust_checkers = ['cargo', 'clippy']
" let g:syntastic_html_checkers = []


nnoremap <C-p> :Files<CR>
nnoremap gd :YcmCompleter GoTo<CR>

" TODO: set this depending on if parcel is running
autocmd FileType html,css,js,scss set backupcopy=yes

let g:mta_filetypes = {'javascript': 1,  'html' : 1, 'xhtml' : 1, 'xml' : 1, 'jinja' : 1 }
let g:indentLine_fileTypeExclude = ['tex']

let g:tex_flavor = 'latex'

set guicursor=
