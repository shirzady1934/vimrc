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

cp .vimrc "$HOME/.vimrc"

echo "==> Installing plugins with Vundle..."
vim +PluginInstall +qall || true

echo "==> Installing Java 17 (required by YCM jdt.ls for Java support)..."
if ! command -v java >/dev/null 2>&1 || ! java -version 2>&1 | grep -q 'version "17\|version "2[0-9]'; then
  if [ "$PKG" = "dnf" ]; then
    sudo dnf install -y java-17-openjdk-devel || echo "  WARNING: java-17 install failed; Java completion will be skipped."
  elif [ "$PKG" = "apt" ]; then
    sudo apt-get install -y openjdk-17-jdk || echo "  WARNING: java-17 install failed; Java completion will be skipped."
  fi
else
  echo "  Java already available: $(java -version 2>&1 | head -1)"
fi

echo "==> Building YouCompleteMe..."
cd "$HOME/.vim/bundle/YouCompleteMe"
git submodule update --init --recursive
git clean -xfd

# Build flags — add --java-completer only when java 17+ is present
YCM_FLAGS="--go-completer --rust-completer --ts-completer"
if command -v java >/dev/null 2>&1 && java -version 2>&1 | grep -qE 'version "1[7-9]|version "2[0-9]'; then
  YCM_FLAGS="$YCM_FLAGS --java-completer"
  echo "  Java 17+ found — including Java completer."
else
  echo "  Java 17+ not found — skipping Java completer."
fi

python3 install.py $YCM_FLAGS

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

# ---------------------------------
# Kubernetes tools
# ---------------------------------
echo "==> Installing Kubernetes tools..."

# kubeconform — fast K8s manifest validator
if ! command -v kubeconform >/dev/null 2>&1; then
  KCONF_VER=$(curl -s https://api.github.com/repos/yannh/kubeconform/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4)
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64)  ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
  esac
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  curl -sL "https://github.com/yannh/kubeconform/releases/download/${KCONF_VER}/kubeconform-${OS}-${ARCH}.tar.gz" \
    | tar -xz -C /tmp kubeconform
  sudo mv /tmp/kubeconform /usr/local/bin/kubeconform
  echo "  kubeconform ${KCONF_VER} installed."
else
  echo "  kubeconform already installed: $(kubeconform -v 2>&1 | head -1)"
fi

# yamllint — YAML linter (used by ALE for all YAML files)
echo "==> Installing yamllint..."
if command -v pip3 >/dev/null 2>&1; then
  pip3 install --user yamllint || true
elif command -v pip >/dev/null 2>&1; then
  pip install --user yamllint || true
else
  echo "  pip not found; skipping yamllint." >&2
fi

# ---------------------------------
# Docker tools
# ---------------------------------
echo "==> Installing hadolint (Dockerfile linter)..."
if ! command -v hadolint >/dev/null 2>&1; then
  HADOLINT_VER=$(curl -s https://api.github.com/repos/hadolint/hadolint/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4)
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64)  ARCH="x86_64" ;;
    aarch64) ARCH="arm64"  ;;
  esac
  OS=$(uname -s)
  curl -sL "https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VER}/hadolint-${OS}-${ARCH}" \
    -o /tmp/hadolint
  chmod +x /tmp/hadolint
  sudo mv /tmp/hadolint /usr/local/bin/hadolint
  echo "  hadolint ${HADOLINT_VER} installed."
else
  echo "  hadolint already installed: $(hadolint --version 2>&1 | head -1)"
fi

# ---------------------------------
# Shell tools
# ---------------------------------
echo "==> Installing shellcheck..."
if ! command -v shellcheck >/dev/null 2>&1; then
  if [ "$PKG" = "dnf" ]; then
    sudo dnf install -y shellcheck
  elif [ "$PKG" = "apt" ]; then
    sudo apt-get install -y shellcheck
  fi
else
  echo "  shellcheck already installed: $(shellcheck --version | head -2 | tail -1)"
fi

echo "==> Installing shfmt (shell formatter)..."
if ! command -v shfmt >/dev/null 2>&1; then
  if command -v go >/dev/null 2>&1; then
    go install mvdan.cc/sh/v3/cmd/shfmt@latest
  else
    SHFMT_VER=$(curl -s https://api.github.com/repos/mvdan/sh/releases/latest \
      | grep '"tag_name"' | cut -d'"' -f4)
    ARCH=$(uname -m)
    case "$ARCH" in
      x86_64)  ARCH="amd64" ;;
      aarch64) ARCH="arm64" ;;
    esac
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    curl -sL "https://github.com/mvdan/sh/releases/download/${SHFMT_VER}/shfmt_${SHFMT_VER}_${OS}_${ARCH}" \
      -o /tmp/shfmt
    chmod +x /tmp/shfmt
    sudo mv /tmp/shfmt /usr/local/bin/shfmt
    echo "  shfmt ${SHFMT_VER} installed."
  fi
else
  echo "  shfmt already installed: $(shfmt --version)"
fi

echo
echo "All set! Open Vim and check:"
echo "  :echo exists(':YcmRestartServer')   (should be 2)"
echo "  :ALEInfo                             (should list active linters)"
echo
echo "K8s keybindings (inside any .yaml/.yml file):"
echo "  <leader>ka  kubectl apply -f %"
echo "  <leader>kd  kubectl delete -f %"
echo "  <leader>kD  kubectl apply --dry-run=server -f %"
echo "  <leader>kv  kubeconform -strict -summary %"
echo "  <leader>ke  kubectl explain <word-under-cursor>"
echo
echo "Shell keybindings (inside .sh/.bash files):"
echo "  <leader>sr  run script with bash"
echo "  <leader>sc  shellcheck current file"
