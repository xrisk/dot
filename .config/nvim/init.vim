let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()
Plug 'sheerun/vim-polyglot'
" Plug 'psf/black', { 'for': 'python' }
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'vim-airline/vim-airline'
" Plug 'https://github.com/itchyny/lightline.vim'
" Plug 'vim-airline/vim-airline-themes'
Plug 'lervag/vimtex', { 'for' : 'tex' }
" Plug 'lifepillar/vim-solarized8'
Plug 'prettier/vim-prettier', {'do': 'npm install'}
Plug 'Valloric/MatchTagAlways', { 'for': ['html', 'javascript'] }
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() } ,  'for': ['markdown']  }
" Plug 'wlangstroth/vim-racket'
" Plug 'davidhalter/jedi-vim'
" Plug 'xavierchow/vim-swagger-preview'
" Plug 'ycm-core/YouCompleteMe'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
" Plug 'nvie/vim-flake8'
Plug 'rust-lang/rust.vim', { 'for': ['rust'] }
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
Plug 'arcticicestudio/nord-vim'
" Plug 'maxmellon/vim-jsx-pretty'
" Plug 'SirVer/ultisnips'
" Plug 'honza/vim-snippets'
Plug 'vimwiki/vimwiki', { 'for': 'vimwiki' }
" Plug 'arzg/vim-colors-xcode'
" Plug 'cocopon/iceberg.vim'
Plug 'ap/vim-buftabline'
Plug 'mitsuhiko/vim-jinja'
call plug#end()

set mouse=a

" set expandtab
" set shiftwidth=4
" set softtabstop=4

colorscheme nord
set number
syntax on

" Protect changes between writes. Default values of
" updatecount (200 keystrokes) and updatetime
" (4 seconds) are fine
set swapfile

" protect against crash-during-write
set writebackup
" but do not persist backup after successful write
" set nobackup
" use rename-and-write-new method whenever safe
set backupcopy=auto
" patch required to honor double slash at end
" persist the undo tree for each file
set undofile

set autoread

" autocmd BufWritePost *.c silent ! clang-format -i -style=LLVM "%:p"
" autocmd BufWritePost *.cpp silent ! clang-format -i -style=LLVM "%:p"
" autocmd BufWritePost *.h silent ! clang-format -i -style=LLVM "%:p"

" autocmd BufWritePre *.py execute ":Black"

set clipboard+=unnamedplus

" let g:airline_theme='nord'
let g:vimtex_compiler_method = 'latexmk'


let g:vimtex_view_method = 'skim'
let g:vimtex_quickfix_open_on_warning = 0

noremap <silent> k gk
noremap <silent> j gj
noremap <silent> 0 g0
noremap <silent> $ g$


nnoremap <C-b> :NERDTreeToggle<CR>
nnoremap <leader>r ! racket "%:p"<CR>

set title

" aug QFClose
"   au!
"   au WinEnter * if winnr('$') == 1 && &buftype == "quickfix"|q|endif
" aug END

let g:rustfmt_autosave = 1
let g:ycm_autoclose_preview_window_after_completion = 1

autocmd FileType rust let g:ycm_show_diagnostics_ui = 0

" nnoremap gd :YcmCompleter GoTo<CR>

let g:mta_filetypes = {'javascript': 1,  'html' : 1, 'xhtml' : 1, 'xml' : 1, 'jinja' : 1 }
let g:indentLine_fileTypeExclude = ['tex', 'json', 'markdown']

let g:tex_flavor = 'latex'

let g:vimwiki_global_ext = 0
let g:vimwiki_list = [{'path': '~/vimwiki/',
                       \ 'syntax': 'markdown', 'ext': '.md'}]

" from coc.nvim configuration
"
" TextEdit might fail if hidden is not set.
set hidden

" Some servers have issues with backup files, see #649.
set nobackup
set nowritebackup

" set cmdheight=2
set updatetime=300
set shortmess+=c

if has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif

" Cycle through autocomplete usign <TAB>
" But don't make <TAB> start autocomplete
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

inoremap <silent><expr> <c-space> coc#refresh()

inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references

nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

autocmd CursorHold * silent call CocActionAsync('highlight')

nmap <leader>rn <Plug>(coc-rename)

xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying codeAction to the current buffer.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Remap <C-f> and <C-b> for scroll float windows/popups.
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
  inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
  inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
  vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of language server.
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
" set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Mappings for CoCList
" Show all diagnostics.
nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions.
nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
" Show commands.
nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document.
nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols.
nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list.
nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>

" end coc.nvim recommended configuration

" for navigating splits
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" open new splits to the bottom and to the right
set splitbelow
set splitright

set shortmess=I
set pumheight=10

nnoremap <C-P> :Files<CR>
" nnoremap <C-Shift-T> :Lines<CR>
nnoremap <C-T> :Tags<CR>
" nnoremap <C-S-P> :Lines<CR>

" use term-default for cursor
" set guicursor=

" Max line length that prettier will wrap on: a number or 'auto' (use
" textwidth).
" default: 'auto'
let g:prettier#config#print_width = '80'

" number of spaces per indentation level: a number or 'auto' (use
" softtabstop)
" default: 'auto'
let g:prettier#config#tab_width = '2'

" use tabs instead of spaces: true, false, or auto (use the expandtab setting).
" default: 'auto'
let g:prettier#config#use_tabs = 'false'

" flow|babylon|typescript|css|less|scss|json|graphql|markdown or empty string
" (let prettier choose).
" default: ''
let g:prettier#config#parser = ''

" cli-override|file-override|prefer-file
" default: 'file-override'
let g:prettier#config#config_precedence = 'file-override'

" always|never|preserve
" default: 'preserve'
let g:prettier#config#prose_wrap = 'preserve'

" css|strict|ignore
" default: 'css'
let g:prettier#config#html_whitespace_sensitivity = 'css'

" false|true
" default: 'false'
let g:prettier#config#require_pragma = 'false'

" Define the flavor of line endings
" lf|crlf|cr|all
" defaut: 'lf'
let g:prettier#config#end_of_line = get(g:, 'prettier#config#end_of_line', 'lf')

" faster apparently
let g:python3_host_prog = '/Users/xrisk/.pyenv/versions/3.9.4/bin/python'

let g:lightline = {
	\ 'colorscheme': 'nord',
	\ 'active': {
	\   'left': [ [ 'mode', 'paste' ],
	\             [ 'cocstatus', 'readonly', 'filename', 'modified' ] ]
	\ },
	\ 'component_function': {
	\   'cocstatus': 'coc#status'
	\ },
	\ }

" navigate buftabs
nnoremap <C-9> :bnext<CR>
nnoremap <C-0> :bprev<CR>

" hide buftabs when there's only one buffer
let g:buftabline_show = 1
