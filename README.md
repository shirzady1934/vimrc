# My Vim Configuration

This repository contains a complete and structured `.vimrc` setup optimized for productivity in Go, Python, and general development. It uses Vundle as the plugin manager and includes enhanced navigation, autocompletion, linting, folding, and editor usability features.

---

## Key Features

### Plugin Management
- Uses Vundle for plugin installation and dependency handling.
- Plugins organized by functionality.

### Navigation and UI Enhancements
- NERDTree file explorer with auto-open on startup when no file is provided.
- ctrlp for project-wide fuzzy search.
- vim-anyfold for smarter and deeper folding behavior.

### Completion and Language Intelligence
- YouCompleteMe (YCM) for semantic autocompletion.
- Integrated gopls LSP backend for Go development.
- Improved completion menu interaction:
  - Tab and Shift+Tab cycle through completion items.
  - Enter confirms or inserts newline depending on selection state.

### Linting and Code Quality
- ALE configured to lint only on save, with full control over which linters to run.
- Python linters and formatters: flake8, black, isort.
- Go linters and formatters: gopls, staticcheck, govet, gofmt, goimports.
- Global fixers for whitespace trimming.
- Custom symbols for error and warning indicators.

### Snippet Engine
- UltiSnips and vim-snippets included.
- Key triggers:
  - Expand: Ctrl+J
  - Jump forward: Ctrl+J
  - Jump backward: Ctrl+K

### Go Development Setup
- vim-go integrated with minimal overlap with YCM.
- goimports used as the default formatter.
- Popup documentation enabled.
- Keybindings:
  - gd for definition
  - gr for references
  - K for documentation lookup

### Python Integration
- Optional pyenv autodetection to set python3 provider dynamically.

### Editor Quality of Life
- Four-space indentation, expand tabs, line numbers, UTF-8, ruler.
- termguicolors enabled when supported.
- Split resizing via:
  - Ctrl + Up/Down/Left/Right arrows.
- Smarter statusline-based window separators for cleaner layout.

---

## Installation

### 1. Install Vundle
```sh
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
````
 ### 2. Copy the .vimrc file
 ```sh
cp .vimrc ~/.vimrc
```
## Installation

### 1. Copy the .vimrc file
```sh
cp .vimrc ~/.vimrc
```
### 2. Install Plugins
```sh
$ ./setup.sh
```



## Plugin List

| Category | Plugins |
|----------|---------|
| Core | VundleVim/Vundle.vim |
| UI / Navigation | preservim/nerdtree, kien/ctrlp.vim, pseewald/vim-anyfold |
| Completion / Linting | ycm-core/YouCompleteMe, dense-analysis/ale, fatih/vim-go |
| Snippets | SirVer/ultisnips, honza/vim-snippets |

---

## Requirements

### External Tools
- gopls  
- goimports  
- staticcheck  
- flake8  
- black  
- isort  

### YouCompleteMe
YouCompleteMe requires compilation. Follow the official installation instructions in its repository.

---

## Notes

- Optimized for terminal Vim with a clean and minimal layout.
- Provides strong navigation, formatting, and linting defaults.
- Works reliably across Linux, macOS, and remote SSH development environments.

