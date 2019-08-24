call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-sensible'
Plug 'psf/black'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/nerdtree'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'lervag/vimtex'
Plug 'xavierd/clang_complete'
Plug 'tpope/vim-sleuth'
Plug 'ctrlpvim/ctrlp.vim'
call plug#end()

set mouse=a

set expandtab
set shiftwidth=4
set softtabstop=4

set termguicolors
set background=dark
color solarized8
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

autocmd BufWritePost *.c silent ! clang-format -i -style=LLVM %:p
autocmd BufWritePost *.cpp silent ! clang-format -i -style=LLVM %:p
autocmd BufWritePost *.h silent ! clang-format -i -style=LLVM %:p

autocmd BufWritePre *.py execute ":Black"

set clipboard=unnamed

let g:airline_theme='solarized'
let g:tex_flavor = 'latex'
let g:vimtex_compiler_method = 'latexmk'
let g:vimtex_view_method = 'skim'
let g:vimtex_quickfix_open_on_warning = 0
let g:clang_library_path = '/Library/Developer/CommandLineTools/usr/lib/libclang.dylib'

nnoremap <leader>m :silent make\|redraw!\|cw<CR>

noremap <Esc-Right> gT

noremap <silent> k gk
noremap <silent> j gj
noremap <silent> 0 g0
noremap <silent> $ g$
