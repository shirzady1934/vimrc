#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------
# vimrc bootstrap
# Installs Vim, vim-plug, YouCompleteMe, plus language tools:
# gopls / staticcheck / goimports, flake8 / black / isort,
# yamllint, kubeconform, hadolint, shellcheck, shfmt.
# Supports: apt (Debian/Ubuntu), dnf (Fedora/RHEL), brew (macOS).
# --------------------------------------------

msg()  { printf '==> %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
err()  { printf '[ERR] %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s)"
PKG=""
SUDO="sudo"

# --- detect package manager ---
case "$OS" in
  Linux)
    if have dnf; then
      PKG="dnf"
    elif have apt-get; then
      PKG="apt"
    else
      err "Unsupported Linux package manager (need dnf or apt)."
      exit 1
    fi
    ;;
  Darwin)
    if ! have brew; then
      msg "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    PKG="brew"
    SUDO=""  # brew refuses to run under sudo
    ;;
  *)
    err "Unsupported OS: $OS"
    exit 1
    ;;
esac
msg "Detected package manager: $PKG"

# --- platform helpers ---
arch_pkg() {
  # Normalize arch to common release-asset names.
  # $1: scheme — "amd64" (Go-style) or "x86_64" (raw)
  local raw scheme="${1:-amd64}"
  raw="$(uname -m)"
  case "$scheme:$raw" in
    amd64:x86_64|amd64:amd64) echo "amd64" ;;
    amd64:aarch64|amd64:arm64) echo "arm64" ;;
    x86_64:x86_64|x86_64:amd64) echo "x86_64" ;;
    x86_64:aarch64|x86_64:arm64) echo "arm64" ;;
    *) echo "$raw" ;;
  esac
}
os_lower() { uname -s | tr '[:upper:]' '[:lower:]'; }

# --- install base packages ---
install_base() {
  msg "Installing Vim and build deps..."
  case "$PKG" in
    dnf)
      $SUDO dnf install -y vim-enhanced gcc-c++ make cmake python3-devel git curl
      ;;
    apt)
      $SUDO apt-get update
      $SUDO apt-get install -y vim git curl build-essential cmake python3-dev python3-pip pipx
      ;;
    brew)
      brew install vim git curl cmake python pipx
      ;;
  esac
}

# --- vim-plug ---
install_vim_plug() {
  if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
    msg "Installing vim-plug..."
    curl -fsSLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  else
    msg "vim-plug already installed"
  fi
}

# --- copy .vimrc with backup ---
install_vimrc() {
  local src
  src="$(cd "$(dirname "$0")" && pwd)/.vimrc"
  if [ ! -f "$src" ]; then
    err "No .vimrc found next to setup.sh"
    return 1
  fi
  if [ -f "$HOME/.vimrc" ] && [ ! -L "$HOME/.vimrc" ]; then
    cp "$HOME/.vimrc" "$HOME/.vimrc.bak.$(date +%s)"
    msg "Backed up existing ~/.vimrc"
  fi
  cp "$src" "$HOME/.vimrc"
  msg "Installed ~/.vimrc"
}

# --- Java for YCM jdt.ls (optional) ---
install_java() {
  if have java && java -version 2>&1 | grep -qE 'version "1[7-9]|version "2[0-9]'; then
    msg "Java already available: $(java -version 2>&1 | head -1)"
    return
  fi
  msg "Installing OpenJDK 17 (for YCM Java completer)..."
  case "$PKG" in
    dnf)  $SUDO dnf install -y java-17-openjdk-devel || warn "Java install failed; Java completion will be skipped." ;;
    apt)  $SUDO apt-get install -y openjdk-17-jdk      || warn "Java install failed; Java completion will be skipped." ;;
    brew) brew install --cask temurin@17                || warn "Java install failed; Java completion will be skipped." ;;
  esac
}

# --- install all plugins via vim-plug ---
install_plugins() {
  msg "Installing plugins via vim-plug..."
  vim +'PlugInstall --sync' +qall || true
}

# --- YouCompleteMe build (separate step — flags depend on Java availability) ---
build_ycm() {
  local ycm_dir="$HOME/.vim/plugged/YouCompleteMe"
  if [ ! -d "$ycm_dir" ]; then
    warn "YouCompleteMe not installed by vim-plug; skipping build."
    return
  fi
  msg "Building YouCompleteMe..."
  cd "$ycm_dir"
  git submodule update --init --recursive
  git clean -xfd

  local ycm_flags="--go-completer --rust-completer --ts-completer"
  if have java && java -version 2>&1 | grep -qE 'version "1[7-9]|version "2[0-9]'; then
    ycm_flags="$ycm_flags --java-completer"
    msg "  Java 17+ found — including Java completer."
  else
    msg "  Java 17+ not found — skipping Java completer."
  fi
  python3 install.py $ycm_flags
}

# --- Go tools ---
install_go_tools() {
  if ! have go; then
    warn "Go not found; skipping gopls/goimports/staticcheck."
    return
  fi
  msg "Installing Go tools (gopls, goimports, staticcheck)..."
  go install golang.org/x/tools/gopls@latest
  go install golang.org/x/tools/cmd/goimports@latest
  go install honnef.co/go/tools/cmd/staticcheck@latest
}

# --- Python tools (PEP 668-safe) ---
# Prefers pipx (recommended for CLI tools), falls back to pip --user,
# and last-resort --break-system-packages.
install_py_tool() {
  local tool="$1"
  if have "$tool"; then
    msg "  $tool already installed"
    return
  fi
  if have pipx; then
    pipx install "$tool" >/dev/null 2>&1 && { msg "  $tool installed via pipx"; return; }
  fi
  local pip
  pip="$(command -v pip3 || command -v pip || true)"
  if [ -z "$pip" ]; then
    warn "  Neither pipx nor pip found; skipping $tool."
    return
  fi
  if "$pip" install --user "$tool" >/dev/null 2>&1; then
    msg "  $tool installed via $pip --user"
  elif "$pip" install --user --break-system-packages "$tool" >/dev/null 2>&1; then
    msg "  $tool installed via $pip --user --break-system-packages"
  else
    warn "  Failed to install $tool"
  fi
}

install_python_tools() {
  msg "Installing Python linters/formatters..."
  install_py_tool flake8
  install_py_tool black
  install_py_tool isort
  install_py_tool yamllint
}

# --- kubeconform ---
install_kubeconform() {
  if have kubeconform; then
    msg "kubeconform already installed: $(kubeconform -v 2>&1 | head -1)"
    return
  fi
  msg "Installing kubeconform..."
  local ver os arch
  ver="$(curl -fsSL -o /dev/null -w '%{url_effective}' https://github.com/yannh/kubeconform/releases/latest | sed 's@.*/@@')"
  os="$(os_lower)"
  arch="$(arch_pkg amd64)"
  curl -fsSL "https://github.com/yannh/kubeconform/releases/download/${ver}/kubeconform-${os}-${arch}.tar.gz" \
    | tar -xz -C /tmp kubeconform
  $SUDO mv /tmp/kubeconform /usr/local/bin/kubeconform
  msg "  kubeconform ${ver} installed."
}

# --- hadolint ---
install_hadolint() {
  if have hadolint; then
    msg "hadolint already installed: $(hadolint --version 2>&1 | head -1)"
    return
  fi
  msg "Installing hadolint..."
  local ver os arch
  ver="$(curl -fsSL -o /dev/null -w '%{url_effective}' https://github.com/hadolint/hadolint/releases/latest | sed 's@.*/@@')"
  os="$(uname -s)"
  arch="$(arch_pkg x86_64)"
  curl -fsSL "https://github.com/hadolint/hadolint/releases/download/${ver}/hadolint-${os}-${arch}" -o /tmp/hadolint
  chmod +x /tmp/hadolint
  $SUDO mv /tmp/hadolint /usr/local/bin/hadolint
  msg "  hadolint ${ver} installed."
}

# --- shellcheck ---
install_shellcheck() {
  if have shellcheck; then
    msg "shellcheck already installed: $(shellcheck --version | head -2 | tail -1)"
    return
  fi
  msg "Installing shellcheck..."
  case "$PKG" in
    dnf)  $SUDO dnf install -y ShellCheck || $SUDO dnf install -y shellcheck ;;
    apt)  $SUDO apt-get install -y shellcheck ;;
    brew) brew install shellcheck ;;
  esac
}

# --- shfmt ---
install_shfmt() {
  if have shfmt; then
    msg "shfmt already installed: $(shfmt --version)"
    return
  fi
  msg "Installing shfmt..."
  if [ "$PKG" = "brew" ]; then
    brew install shfmt
    return
  fi
  if have go; then
    go install mvdan.cc/sh/v3/cmd/shfmt@latest
    return
  fi
  local ver os arch
  ver="$(curl -fsSL -o /dev/null -w '%{url_effective}' https://github.com/mvdan/sh/releases/latest | sed 's@.*/@@')"
  os="$(os_lower)"
  arch="$(arch_pkg amd64)"
  curl -fsSL "https://github.com/mvdan/sh/releases/download/${ver}/shfmt_${ver}_${os}_${arch}" -o /tmp/shfmt
  chmod +x /tmp/shfmt
  $SUDO mv /tmp/shfmt /usr/local/bin/shfmt
  msg "  shfmt ${ver} installed."
}

# --- main ---
install_base
install_vimrc
install_vim_plug
install_java
install_plugins
build_ycm
install_go_tools
install_python_tools
install_kubeconform
install_hadolint
install_shellcheck
install_shfmt

cat <<'EOF'

All set! Open Vim and verify:
  :echo exists(':YcmRestartServer')   (should be 2)
  :ALEInfo                            (should list active linters)

K8s keybindings (inside any .yaml/.yml file):
  <leader>ka  kubectl apply -f %
  <leader>kd  kubectl delete -f %
  <leader>kD  kubectl apply --dry-run=server -f %
  <leader>kv  kubeconform -strict -summary %
  <leader>ke  kubectl explain <word-under-cursor>

Shell keybindings (inside .sh/.bash files):
  <leader>sr  run script with bash
  <leader>sc  shellcheck current file
EOF
