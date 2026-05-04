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

" YAML / Kubernetes
Plugin 'stephpy/vim-yaml'
Plugin 'andrewstuart/vim-kubernetes'

" Docker (Dockerfile + docker-compose)
Plugin 'ekalinin/Dockerfile.vim'

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
let g:ycm_auto_hover = ''

function! s:ScrollGoDocPopup(down) abort
  let l:wins = popup_list()
  if empty(l:wins) | return "\<C-" . (a:down ? 'd' : 'u') . ">" | endif
  let l:id = l:wins[0]
  let l:pos = popup_getpos(l:id)
  call popup_setoptions(l:id, {'firstline': max([1, l:pos.firstline + (a:down ? 3 : -3)])})
  return ''
endfunction

nnoremap <expr> <C-d> <SID>ScrollGoDocPopup(1)
nnoremap <expr> <C-u> <SID>ScrollGoDocPopup(0)

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
let g:ale_lint_on_enter = 0
let g:ale_open_list = 1
let g:ale_keep_list_window_open = 0

let g:ale_linters = {
\ 'python':     ['flake8'],
\ 'go':         ['gopls', 'staticcheck', 'govet'],
\ 'yaml':       ['yamllint'],
\ 'sh':         ['shellcheck'],
\ 'bash':       ['shellcheck'],
\ 'zsh':        ['shellcheck'],
\ 'dockerfile': ['hadolint'],
\}
let g:ale_fixers = {
\ 'python':     ['black', 'isort'],
\ 'go':         ['gofmt', 'goimports'],
\ 'sh':         ['shfmt'],
\ 'bash':       ['shfmt'],
\ 'yaml':       ['trim_whitespace', 'remove_trailing_lines'],
\ '*':          ['trim_whitespace', 'remove_trailing_lines'],
\}

let g:ale_sign_error = '✗'
let g:ale_sign_warning = '!'

" shfmt: indent with 4 spaces, follow Google shell style
let g:ale_sh_shfmt_options = '-i 4 -bn -ci'

highlight clear SignColumn

" ---------------------------------
" YAML / Kubernetes
" ---------------------------------
" 2-space indent — K8s/YAML standard
augroup yaml_indent
  autocmd!
  autocmd FileType yaml setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
augroup END

" Detect Kubernetes manifests (apiVersion: / kind: present) and enable
" kubeconform linting only for those files.
function! s:DetectKubernetes() abort
  if search('\v^apiVersion:\s', 'nw') > 0 && search('\v^kind:\s', 'nw') > 0
    let b:ale_linters = ['yamllint', 'kubeconform']
  endif
endfunction

augroup kubernetes_detect
  autocmd!
  autocmd BufRead,BufNewFile *.yaml,*.yml call s:DetectKubernetes()
augroup END

" K8s keybindings (only inside YAML buffers that look like manifests)
augroup kubernetes_keys
  autocmd!
  " <leader>ka  — kubectl apply current file
  autocmd FileType yaml nnoremap <buffer> <leader>ka
        \ :w<CR>:!kubectl apply -f %<CR>
  " <leader>kd  — kubectl delete current file
  autocmd FileType yaml nnoremap <buffer> <leader>kd
        \ :w<CR>:!kubectl delete -f %<CR>
  " <leader>kD  — kubectl dry-run (server) current file
  autocmd FileType yaml nnoremap <buffer> <leader>kD
        \ :w<CR>:!kubectl apply --dry-run=server -f %<CR>
  " <leader>kv  — validate with kubeconform
  autocmd FileType yaml nnoremap <buffer> <leader>kv
        \ :w<CR>:!kubeconform -strict -summary %<CR>
  " <leader>ke  — kubectl explain word under cursor
  autocmd FileType yaml nnoremap <buffer> <leader>ke
        \ :!kubectl explain <cword><CR>
augroup END

" ---------------------------------
" Docker / docker-compose
" ---------------------------------
augroup docker_ft
  autocmd!
  " Treat docker-compose*.yml as YAML (inherits 2-space indent)
  autocmd BufRead,BufNewFile docker-compose*.yml setlocal filetype=yaml
  autocmd BufRead,BufNewFile docker-compose*.yaml setlocal filetype=yaml
  " Dockerfile variants
  autocmd BufRead,BufNewFile Dockerfile*,*.dockerfile setlocal filetype=dockerfile
augroup END

" ---------------------------------
" Shell scripts
" ---------------------------------
augroup shell_ft
  autocmd!
  " Ensure *.sh files are treated as sh (shellcheck works on sh/bash)
  autocmd BufRead,BufNewFile *.sh setlocal filetype=sh
  autocmd BufRead,BufNewFile *.bash setlocal filetype=bash
  " <leader>sr  — run current shell script
  autocmd FileType sh,bash nnoremap <buffer> <leader>sr
        \ :w<CR>:!bash %<CR>
  " <leader>sc  — shellcheck current file (explicit, without ALE)
  autocmd FileType sh,bash nnoremap <buffer> <leader>sc
        \ :w<CR>:!shellcheck %<CR>
augroup END

" ---------------------------------
" Go setup (vim-go + gopls)
" ---------------------------------
let g:go_def_mapping_enabled = 0
let g:go_gopls_enabled = 1
let g:go_code_completion_enabled = 0
let g:go_imports_autosave = 1
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
