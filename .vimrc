" ============================================================================
" VIM-PLUG SETUP
" ============================================================================
" Install vim-plug if not already installed
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

" File navigation
Plug 'preservim/nerdtree'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Status line
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Code intelligence & completion
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" CoC language extensions
let g:coc_global_extensions = [
\ 'coc-rust-analyzer',
\ 'coc-go',
\ 'coc-pyright',
\ 'coc-tsserver',
\ 'coc-json',
\ 'coc-yaml',
\ 'coc-docker',
\ 'coc-toml',
\ 'coc-markdownlint',
\ ]

" Polyglot sets docker-compose files to 'yaml.docker-compose'; treat them as
" YAML in CoC so coc-yaml attaches and applies the compose schema
let g:coc_filetype_map = {'yaml.docker-compose': 'yaml'}

" Linting (let CoC handle LSP; must be set before ALE loads)
let g:ale_disable_lsp = 1
Plug 'dense-analysis/ale'

" Git integration
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" Syntax highlighting
Plug 'sheerun/vim-polyglot'

" Editing enhancements
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'jiangmiao/auto-pairs'

" Markdown preview in the browser
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug'] }

" Color scheme
Plug 'joshdick/onedark.vim'

call plug#end()

" ============================================================================
" GENERAL SETTINGS
" ============================================================================
set nocompatible
syntax enable
set number                    " Show line numbers
set cursorline                " Highlight current line
set showmatch                 " Highlight matching brackets
set incsearch                 " Incremental search
set hlsearch                  " Highlight search results
set ignorecase                " Case insensitive search
set smartcase                 " Case sensitive if uppercase present
set mouse=a                   " Enable mouse
set encoding=utf-8
set autoindent
set smartindent
set expandtab                 " Use spaces instead of tabs
set tabstop=4
set shiftwidth=4
set softtabstop=4
set clipboard=unnamed         " Use system clipboard
set hidden                    " Allow hidden buffers
set updatetime=300            " Faster completion
set signcolumn=yes            " Always show sign column

" ============================================================================
" COLOR SCHEME
" ============================================================================
" Enable 24-bit true colors (recommended for OneDark)
if (has("termguicolors"))
  set termguicolors
endif

set background=dark
colorscheme onedark

" ============================================================================
" KEY MAPPINGS
" ============================================================================
let mapleader = " "

" NERDTree
nnoremap <leader>n :NERDTreeToggle<CR>
nnoremap <leader>f :NERDTreeFind<CR>

" FZF
nnoremap <C-p> :Files<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>g :Rg<CR>

" Window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Clear search highlighting
nnoremap <leader><space> :nohlsearch<CR>

" ============================================================================
" COC.NVIM SETTINGS
" ============================================================================
" Use Tab for trigger completion
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <cr> to confirm completion
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" GoTo code navigation
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Refactoring, code actions, and diagnostics
nmap <silent> <leader>rn <Plug>(coc-rename)
nmap <silent> <leader>a <Plug>(coc-codeaction-cursor)
xmap <silent> <leader>a <Plug>(coc-codeaction-selected)
nmap <silent> [d <Plug>(coc-diagnostic-prev)
nmap <silent> ]d <Plug>(coc-diagnostic-next)

" Format the current buffer
nnoremap <silent> <leader>cf :call CocActionAsync('format')<CR>

" Show documentation
nnoremap <silent> K :call ShowDocumentation()<CR>

function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

" Rust tools
nnoremap <silent> <leader>rr :CocCommand rust-analyzer.run<CR>
nnoremap <silent> <leader>rt :CocCommand rust-analyzer.testCurrent<CR>
nnoremap <silent> <leader>re :CocCommand rust-analyzer.expandMacro<CR>
nnoremap <silent> <leader>rs :CocCommand rust-analyzer.analyzerStatus<CR>

" Markdown preview
nnoremap <silent> <leader>mp :MarkdownPreviewToggle<CR>

augroup make_settings
  autocmd!
  " Makefile recipes must be indented with real tabs
  autocmd FileType make setlocal noexpandtab tabstop=4 shiftwidth=4 softtabstop=0
augroup END

augroup rust_settings
  autocmd!
  autocmd FileType rust setlocal tabstop=4 shiftwidth=4 softtabstop=4
augroup END

" ============================================================================
" ALE SETTINGS
" ============================================================================
let g:ale_linters = {
\   'python': ['flake8', 'pylint'],
\   'sql': ['sqlfluff'],
\   'make': ['checkmake'],
\}
let g:ale_fixers = {
\   'python': ['black', 'isort'],
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\}
let g:ale_fix_on_save = 1
let g:ale_sign_error = '✗'
let g:ale_sign_warning = '⚠'

" ============================================================================
" NERDTREE SETTINGS
" ============================================================================
let NERDTreeShowHidden=1
let NERDTreeIgnore=['\.pyc$', '__pycache__', '.git$']

" ============================================================================
" AIRLINE SETTINGS
" ============================================================================
let g:airline_theme='onedark'
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
