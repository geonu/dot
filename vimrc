call plug#begin('~/.local/share/nvim/plugged')

" Plug list -----------------------------------------------------------------

" ColorScheme
Plug 'morhetz/gruvbox'

" Syntax
Plug 'sheerun/vim-polyglot'

" Syntax Helper
Plug 'scrooloose/syntastic'
if has('python2')
    Plug 'Rykka/riv.vim'
endif

" Git
Plug 'airblade/vim-gitgutter'
Plug 'rhysd/committia.vim'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/gv.vim'

" LSP
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'ryanolsonx/vim-lsp-python'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

" Util
Plug 'preservim/nerdtree'
Plug 'ryanoasis/vim-devicons'
Plug 'vimwiki/vimwiki'
Plug 'bling/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'benmills/vimux'

function! DoRemote(arg)
  UpdateRemotePlugins
endfunction

" End plugin list -------------------------------------------------------------
call plug#end()

filetype plugin on
filetype plugin indent on

set clipboard=unnamed

" Set Leader
let mapleader = "\<Space>"

" buffer
set hidden
nmap <leader>T :enew<cr>
nmap <leader>l :bnext<CR>
nmap <leader>h :bprevious<CR>
nmap <leader>bq :bp <BAR> bd #<CR>

" Set Color Scheme.
colo gruvbox

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

" Plugin Setup ---------------------------------------------------------------

" nerdtree
map <Leader>n :NERDTreeToggle<CR>
autocmd BufEnter * lcd %:p:h

" LSP
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <cr>    pumvisible() ? "\<C-y>" : "\<cr>"
imap <c-space> <Plug>(asyncomplete_force_refresh)
set completeopt=menuone,noinsert,noselect
autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif


"" LSP-Python
if executable('pyls')
    " pip install python-language-server
    au User lsp_setup call lsp#register_server({
        \ 'name': 'pyls',
        \ 'cmd': {server_info->['pyls']},
        \ 'whitelist': ['python'],
        \ })
endif
function! s:on_lsp_buffer_enabled() abort
    setlocal omnifunc=lsp#complete
    setlocal signcolumn=yes
    nmap <buffer> gd <plug>(lsp-definition)
    nmap <buffer> <f2> <plug>(lsp-rename)
    " refer to doc to add more commands
endfunction

augroup lsp_install
    au!
    " call s:on_lsp_buffer_enabled only for languages that has the server registered.
    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END

" vim-markdown
let g:vim_markdown_folding_disabled=1

" gitgutter
set signcolumn=yes
autocmd BufWritePost * GitGutter

" Syntastic
let g:syntastic_check_on_wq = 0

let g:syntastic_python_checkers = ['flake8']

let g:syntastic_javascript_checkers=['eslint']

" Airline
let g:airline_theme='gruvbox'
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#fnamemod = ':t'
let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#tabline#buffer_nr_format = '%s:'

" FZF
function! s:find_files()
    let git_dir = system('git rev-parse --show-toplevel 2> /dev/null')[:-2]
    if git_dir != ''
        execute 'GFiles' git_dir
    else
        execute 'Files'
    endif
endfunction
command! ProjectFiles execute s:find_files()
nnoremap <C-p> :ProjectFiles<CR>

"" FZF preview
let g:fzf_preview_window = 'right:60%'
command! -bang -nargs=? -complete=dir Files
    \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'options': ['--layout=reverse', '--info=inline']}), <bang>0)

"" fzf.vim
nnoremap <silent> <Leader>k :Rg <C-R><C-W><CR>

" vim-jsx
let g:jsx_ext_required = 0

" vim-json
let g:vim_json_syntax_conceal=0

" vimwiki
let g:vimwiki_list = [
\ {'path': '/Users/geonu/workspace/geonu.github.io/content/wiki/',
\  'ext': '.md'}
\]
let g:vimwiki_global_ext = 0
let g:vimwiki_conceallevel = 0

function! NewTemplate()
    let l:wiki_directory = v:false

    for wiki in g:vimwiki_list
        if expand('%:p:h') . '/' == wiki.path
            let l:wiki_directory = v:true
            break
        endif
    endfor

    if !l:wiki_directory
        return
    endif

    if line("$") > 1
        return
    endif

    let l:template = []
    call add(l:template, '---')
    call add(l:template, 'title   : ')
    call add(l:template, 'summary : ')
    call add(l:template, 'date    : ' . strftime('%Y-%m-%d %H:%M:%S +0900'))
    call add(l:template, 'tags    : ')
    call add(l:template, 'draft  : true')
    call add(l:template, 'parent  : ')
    call add(l:template, '---')
    call setline(1, l:template)
    execute 'normal! G'
    execute 'normal! $'

    echom 'new wiki page has created'
endfunction

augroup vimwikiauto
    autocmd BufRead,BufNewFile *wiki/*.md call NewTemplate()
augroup END
