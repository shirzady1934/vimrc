#!/usr/bin/env bash
set -euo pipefail

echo "==> Detecting package manager..."
PKG=""
if command -v dnf >/dev/null 2>&1; then
  PKG="dnf"
elif command -v apt-get >/dev/null 2>&1; then
  PKG="apt"
else
  echo "Unsupported distro (needs dnf or apt). Exiting." >&2
  exit 1
fi

echo "==> Installing Vim (+python3) and build deps..."
if [ "$PKG" = "dnf" ]; then
  sudo dnf install -y vim-enhanced gcc-c++ make cmake python3-devel git curl
elif [ "$PKG" = "apt" ]; then
  sudo apt-get update
  sudo apt-get install -y vim git curl build-essential cmake python3-dev
fi

echo "==> Ensuring Vundle is installed..."
if [ ! -d "$HOME/.vim/bundle/Vundle.vim" ]; then
  git clone https://github.com/VundleVim/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim"
else
  (cd "$HOME/.vim/bundle/Vundle.vim" && git pull --ff-only || true)
fi

cp .vimrc $HOME/.vimrc

echo "==> Installing plugins with Vundle..."
vim +PluginInstall +qall || true

echo "==> Building YouCompleteMe with Vim's Python..."
# Get Vim's python executable if possible; fallback to /usr/bin/python3
cd "$HOME/.vim/bundle/YouCompleteMe"
git submodule update --init --recursive
git clean -xfd
python  install.py --all

echo "==> Installing Go tools (gopls, goimports, staticcheck)..."
if command -v go >/dev/null 2>&1; then
  go install golang.org/x/tools/gopls@latest
  go install golang.org/x/tools/cmd/goimports@latest
  go install honnef.co/go/tools/cmd/staticcheck@latest
  if ! grep -q 'GOPATH' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export GOPATH="${GOPATH:-$HOME/go}"' >> "$HOME/.bashrc"
    echo 'export PATH="$GOPATH/bin:$PATH"' >> "$HOME/.bashrc"
  fi
else
  echo "Go not found; skipping Go tools. Install Go and rerun those lines." >&2
fi

echo "==> Installing Python linters/formatters (flake8, black, isort)..."
if command -v pip >/dev/null 2>&1; then
  pip install --user flake8 black isort || true
elif command -v pip3 >/dev/null 2>&1; then
  pip3 install --user flake8 black isort || true
else
  echo "pip not found; skipping Python tools." >&2
fi

echo
echo "All set! Open Vim and check:"
echo "  :echo exists(':YcmRestartServer')   (should be 2)"
echo "  :ALEInfo                             (should list active linters)"
echo "Toggle NERDTree with Ctrl-n. Enjoy 🎉"

