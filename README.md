# My Vim Configuration

A structured `.vimrc` tuned for Go, Python, shell, Docker, and Kubernetes
work. vim-plug is the plugin manager; YouCompleteMe (with gopls) handles
completion; ALE handles linting and formatting on save.

---

## Features

### Plugin management
- [vim-plug](https://github.com/junegunn/vim-plug) — parallel installs,
  lazy-loading, and auto-bootstrap on first launch.
- Plugins grouped by purpose in `.vimrc`.
- Lazy-loaded: NERDTree (on command), ctrlp (on command), vim-go (only
  in Go buffers), vim-yaml + vim-kubernetes (only in YAML buffers).

### Navigation and UI
- NERDTree — file tree, auto-opens on bare `vim`.
- ctrlp — project-wide fuzzy file finder.
- vim-anyfold — indent-based folding for all filetypes.

### Completion and language intelligence
- YouCompleteMe with gopls LSP for Go.
- `<Tab>` / `<S-Tab>` cycle the completion menu.
- `<CR>` confirms the highlighted candidate or inserts newline.

### Linting and formatting (ALE, on save)
| Filetype | Linters | Fixers |
|---|---|---|
| Python | flake8 | black, isort |
| Go | gopls, staticcheck, govet | gofmt, goimports |
| Shell (sh / bash / zsh) | shellcheck | shfmt (`-i 4 -bn -ci`) |
| YAML | yamllint | trim whitespace |
| Kubernetes YAML | yamllint + kubeconform | — |
| Dockerfile | hadolint | — |

### Snippets
- UltiSnips + vim-snippets.
- Expand / jump: `<C-j>` forward, `<C-k>` back (Tab is reserved for completion).

### Editor quality of life
- 4-space indent, line numbers, UTF-8, ruler.
- 2-space indent auto-applied to YAML.
- `termguicolors` when supported.
- Resize splits with `Ctrl + Arrow keys`.
- Persistent undo, mouse, system clipboard, smart search.
- Statusline-based dashed window separators.

---

## Keybindings

Default `<leader>` is `<Space>`.

### Kubernetes (any `.yaml` / `.yml` buffer)
| Key | Action |
|---|---|
| `<leader>ka` | `kubectl apply -f %` |
| `<leader>kd` | `kubectl delete -f %` |
| `<leader>kD` | `kubectl apply --dry-run=server -f %` |
| `<leader>kv` | `kubeconform -strict -summary %` |
| `<leader>ke` | `kubectl explain <word-under-cursor>` |

### Shell (`.sh` / `.bash`)
| Key | Action |
|---|---|
| `<leader>sr` | run script with bash |
| `<leader>sc` | `shellcheck %` |

### Go (`.go`)
| Key | Action |
|---|---|
| `gd` | go to definition (`vim-go`) |
| `gr` | find references |
| `K` | doc lookup (popup) |
| `<C-d>` / `<C-u>` | scroll doc popup |

### Python (`.py`, via YCM)
| Key | Action |
|---|---|
| `gd` | `YcmCompleter GoTo` |
| `gr` | `YcmCompleter GoToReferences` |
| `K` | `YcmCompleter GetDoc` |

### Splits / windows
| Key | Action |
|---|---|
| `<C-n>` | toggle NERDTree |
| `<C-Up>` / `<C-Down>` | shrink / grow horizontal |
| `<C-Left>` / `<C-Right>` | shrink / grow vertical |

---

## Plugin list

| Category | Plugins | Lazy |
|---|---|---|
| UI / Navigation | preservim/nerdtree | on command |
|                 | kien/ctrlp.vim | on command |
|                 | pseewald/vim-anyfold | eager |
| Completion / Linting | ycm-core/YouCompleteMe | eager |
|                      | dense-analysis/ale | eager |
| Languages | fatih/vim-go | `for: go` |
|           | stephpy/vim-yaml | `for: yaml` |
|           | andrewstuart/vim-kubernetes | `for: yaml` |
|           | ekalinin/Dockerfile.vim | eager |
| Snippets | SirVer/ultisnips, honza/vim-snippets | eager |

---

## Installation

```sh
git clone https://github.com/shirzady1934/vimrc ~/vimrc
cd ~/vimrc
./setup.sh
```

`setup.sh` installs Vim (with Python 3), build deps, Vundle, all plugins,
YouCompleteMe (with Go / Rust / TS, optionally Java), and the external
tools listed below.

---

## External tools installed by setup.sh

| Tool | Purpose |
|---|---|
| `gopls`, `goimports`, `staticcheck` | Go LSP, formatter, linter |
| `flake8`, `black`, `isort` | Python linter / formatter / import sorter |
| `yamllint` | YAML linter |
| `kubeconform` | Fast K8s manifest validator |
| `hadolint` | Dockerfile linter |
| `shellcheck` | Shell script linter |
| `shfmt` | Shell script formatter |
| OpenJDK 17+ (optional) | Enables YCM Java completer |

### Supported package managers

- Linux: `apt` (Debian/Ubuntu), `dnf` (Fedora/RHEL)
- macOS: `brew`

### PEP 668

On Ubuntu 24+ / Fedora 39+, system Python is externally managed.
`setup.sh` prefers `pipx` for CLI tools (`flake8`, `black`, `isort`,
`yamllint`) and falls back to `pip --user --break-system-packages`
when `pipx` isn't available.

---

## Notes

- Optimized for terminal Vim; works over SSH (clipboard works with
  `+clipboard` build).
- ALE runs on save only — no flicker on every keystroke.
- YouCompleteMe diagnostics are off; ALE is the single source of truth
  for lint messages.
- The `colorscheme` is `desert` (built-in). Swap to taste.
