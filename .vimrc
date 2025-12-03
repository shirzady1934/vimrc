" ---------------------------------
" Vundle Setup
" ---------------------------------
set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" Core
Plugin 'VundleVim/Vundle.vim'

" UI & navigation
Plugin 'preservim/nerdtree'
Plugin 'kien/ctrlp.vim'
Plugin 'pseewald/vim-anyfold'

" Completion, linting, language tooling
Plugin 'ycm-core/YouCompleteMe'
Plugin 'dense-analysis/ale'
Plugin 'fatih/vim-go'

" Snippets
Plugin 'SirVer/ultisnips'
Plugin 'honza/vim-snippets'

call vundle#end()
filetype plugin indent on

" ---------------------------------
" General Settings
" ---------------------------------
set tabstop=4 shiftwidth=4 softtabstop=4 expandtab
set autoindent ruler nu encoding=utf-8
set updatetime=300
set signcolumn=yes
if has('termguicolors') | set termguicolors | endif
syntax on
colorscheme desert

" ---------------------------------
" Folding
" ---------------------------------
autocmd FileType * AnyFoldActivate
set foldlevel=99
let g:EclimCompletionMethod = 'omnifunc'

" ---------------------------------
" File tree (NERDTree)
" ---------------------------------
nnoremap <C-n> :NERDTreeToggle<CR>
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
autocmd BufEnter * if winnr('$')==1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" ---------------------------------
" Completion UX (all languages)
" ---------------------------------
set completeopt=menu,menuone,noselect
set shortmess+=c
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
silent! iunmap <CR>
if exists('*complete_info')
  inoremap <expr> <CR> pumvisible()
        \ ? (complete_info().selected == -1 ? "\<C-e>\<CR>" : "\<C-y>")
        \ : "\<CR>"
else
  inoremap <expr> <CR> pumvisible() ? "\<C-e>\<CR>" : "\<CR>"
endif

" ---------------------------------
" YouCompleteMe
" ---------------------------------
let g:ycm_confirm_extra_conf = 0
let g:ycm_show_diagnostics_ui = 0
let g:ycm_filetype_whitelist = { '*': 1 }

" gopls via YCM (Go)
let g:ycm_language_server = [
\ { 'name': 'gopls',
\   'cmdline': ['gopls'],
\   'filetypes': ['go'],
\   'project_root_files': ['go.work', 'go.mod', '.git']
\ }
\]

" ---------------------------------
" ALE (lint on save + autofix)
" ---------------------------------
let g:ale_linters_explicit = 1
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_insert_leave = 0
let g:ale_lint_on_save = 1
let g:ale_lint_on_save = 0
let g:ale_lint_on_enter = 0
let g:ale_open_list = 1
let g:ale_keep_list_window_open = 0

let g:ale_linters = {
\ 'python': ['flake8'],
\ 'go':     ['gopls', 'staticcheck', 'govet'],
\}
let g:ale_fixers = {
\ 'python': ['black', 'isort'],
\ 'go':     ['gofmt', 'goimports'],
\ '*':      ['trim_whitespace', 'remove_trailing_lines'],
\}

let g:ale_sign_error = '✗'
let g:ale_sign_warning = '!'

highlight clear SignColumn

" ---------------------------------
" Go setup (vim-go + gopls)
" ---------------------------------
let g:go_def_mapping_enabled = 0
let g:go_gopls_enabled = 1
let g:go_code_completion_enabled = 0
let g:go_imports_autosave = 
let g:go_fmt_command = 'goimports'
let g:go_doc_popup_window = 1
let g:go_echo_go_info = 0

augroup go_keys
  autocmd!
  autocmd FileType go nmap <buffer> gd <Plug>(go-def)
  autocmd FileType go nmap <buffer> gr <Plug>(go-referrers)
  autocmd FileType go nmap <buffer> K  <Plug>(go-doc)
augroup END

" ---------------------------------
" Python host (optional, if using pyenv)
" ---------------------------------
if executable('pyenv')
  let g:python3_host_prog = trim(system('pyenv which python3'))
endif

" ---------------------------------
" UltiSnips triggers (avoid Tab conflict)
" ---------------------------------
let g:UltiSnipsExpandTrigger='<c-j>'
let g:UltiSnipsJumpForwardTrigger='<c-j>'
let g:UltiSnipsJumpBackwardTrigger='<c-k>'

" Resize splits with Ctrl + Arrow keys
nnoremap <C-Up>    :resize -2<CR>
nnoremap <C-Down>  :resize +2<CR>
nnoremap <C-Left>  :vertical resize -2<CR>
nnoremap <C-Right> :vertical resize +2<CR>


" Show a per-window statusline (used as the horizontal separator)
set laststatus=2

" Function: dashed line only for windows that have another window below
function! s:UpdateDashedSeparators() abort
  let l:cur = winnr()
  " Visit each window and set its statusline
  for l:w in range(1, winnr('$'))
    execute l:w . 'wincmd w'
    " If there is a window below this one, draw dashes. Otherwise clear it.
    if winnr('j') != winnr()
      setlocal statusline=%{repeat('-',winwidth(0))}
    else
      setlocal statusline=
    endif
  endfor
  " Go back to the original window
  execute l:cur . 'wincmd w'
endfunction

augroup OnlyMiddleDashed
  autocmd!
  autocmd VimEnter,WinEnter,WinLeave,BufWinEnter,VimResized * call s:UpdateDashedSeparators()
augroup END

" No colors; keep separators plain
highlight StatusLine   cterm=NONE ctermfg=NONE ctermbg=NONE
highlight StatusLineNC cterm=NONE ctermfg=NONE ctermbg=NONE

