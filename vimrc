call plug#begin('~/.local/share/nvim/plugged')

" Plug list -----------------------------------------------------------------

" ColorScheme
Plug 'junegunn/seoul256.vim'

" Syntax
Plug 'plasticboy/vim-markdown'
Plug 'StanAngeloff/php.vim'
Plug 'honza/dockerfile.vim'
Plug 'elzr/vim-json'

Plug 'othree/html5.vim'
Plug 'hail2u/vim-css3-syntax'
Plug 'Glench/Vim-Jinja2-Syntax'
Plug 'pangloss/vim-javascript'
Plug 'mxw/vim-jsx'
Plug 'stephpy/vim-yaml'

" Syntax Helper
Plug 'scrooloose/syntastic'
Plug 'cespare/vim-toml'
Plug 'alvan/vim-closetag'
if has('python2')
    Plug 'Rykka/riv.vim'
endif

" Git
Plug 'airblade/vim-gitgutter'
Plug 'rhysd/committia.vim'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/gv.vim'

" Util
Plug 'vimwiki/vimwiki'
Plug 'godlygeek/tabular'
Plug 'junegunn/vim-xmark', { 'do': 'make' }
Plug 'bling/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'ervandew/supertab'

function! DoRemote(arg)
  UpdateRemotePlugins
endfunction
"Plug 'Shougo/deoplete.nvim', { 'do': function('DoRemote') }

" End plugin list -------------------------------------------------------------
call plug#end()

filetype plugin on
filetype plugin indent on

" Set Color Scheme.
let g:seoul256_background = 236
colo seoul256

" Use backspace
set backspace=2

" Syntax highlighting.
syntax on

" Set tab characters apart.
set listchars=tab:↹\

" Detect modeline hints.
set modeline

" StatusLine
set laststatus=2

" Prefer UTF-8.
set encoding=utf-8
set fileencodings=ucs-bom,utf-8,cp949,korea,iso-2022-kr
set termencoding=utf-8

" Set file format.
set fileformat=unix

" Use mouse.
set mouse=a

" Show line number.
set nu

" Show coordinates.
set ruler

" Highlight search contents.
set hlsearch

" Softtab -- use spaces instead tabs.
set expandtab
set autoindent
set ts=4 sw=4 sts=4

" Show Hardtab
highlight HardTab cterm=underline
autocmd BufWinEnter * 2 match HardTab /\t\+/

" Set cursor line highlighting
set cursorline

" Some additional syntax highlighters.
autocmd BufNewFile,BufRead *.wsgi setfiletype python

" Python preferences
autocmd FileType python setlocal ts=4 sw=4 sts=4

" Web
autocmd FileType html setlocal ts=2 sw=2 sts=2
autocmd FileType javascript setlocal ts=2 sw=2 sts=2
autocmd FileType css setlocal ts=2 sw=2 sts=2
autocmd FileType scss setlocal ts=2 sw=2 sts=2

" If use FileType, not working about tab.
autocmd BufNewFile,BufRead *.html setlocal ts=2 sw=2 sts=2

" RST
autocmd Filetype rst setlocal ts=3 sw=3 sts=3

" Git Commit
autocmd Filetype gitcommit set spell textwidth=72

" DockerFile
autocmd BufNewFile,BufRead Dockerfile* set filetype=dockerfile

" Whitespaces
highlight WhitespaceEOL ctermbg=red guibg=red
match WhitespaceEOL /\s\+$/

" default colorcolumn
set colorcolumn=80
highlight OverLength ctermbg=red ctermfg=white

" Highlight for over 80 column text for python.
autocmd FileType python set colorcolumn=80
autocmd FileType python match OverLength /\%>80v.\+\|\s\+$\|^\s*\n\+\%$/

autocmd FileType php set colorcolumn=100
autocmd FileType php match OverLength /\%>100v.\+\|\s\+$\|^\s*\n\+\%$/

" #!! | Shebang
inoreabbrev <expr> #!! "#!/usr/bin/env" . (empty(&filetype) ? '' : ' '.&filetype)

"split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" vim-markdown
let g:vim_markdown_folding_disabled=1

" gitgutter
set signcolumn=yes

" Syntastic
let g:syntastic_check_on_wq = 0

let g:syntastic_python_checkers = ['flake8']

let g:syntastic_javascript_checkers=['eslint']

" Airline
let g:airline_theme='bubblegum'
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#fnamemod = ':t'
let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#tabline#buffer_nr_format = '%s:'

" FZF
nnoremap <C-p> :Files<Cr>

"" FZF preview
let g:fzf_preview_window = 'right:60%'
command! -bang -nargs=? -complete=dir Files
    \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'options': ['--layout=reverse', '--info=inline']}), <bang>0)

" vim-jsx
let g:jsx_ext_required = 0

" vim-json
let g:vim_json_syntax_conceal=0

set clipboard=unnamed

" vimwiki
let g:vimwiki_list = [{'path': '/Users/geonu/workspace/geonu.github.io/content/wiki/'}]
let g:vimwiki_global_ext = 0
let g:vimwiki_conceallevel = 0
