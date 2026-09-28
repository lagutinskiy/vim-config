#!/usr/bin/env bash
# Set up this vim config on openSUSE Tumbleweed: install the external tools
# it relies on, install a Nerd Font for airline, and symlink the config files
# from this repo into $HOME.
# Safe to re-run: installed packages are skipped and existing links are left
# alone.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"

if ! command -v zypper >/dev/null 2>&1; then
  echo "This script is for openSUSE (zypper not found)." >&2
  exit 1
fi

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
fi

mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

# ----------------------------------------------------------------------------
# Dependencies
# ----------------------------------------------------------------------------

# gvim provides a vim built with +clipboard (the plain vim package lacks it,
# and the config uses clipboard=unnamed). CoC needs node; FZF's :Rg needs
# ripgrep. The Python linters and fixers are used by ALE.
$SUDO zypper --non-interactive install --no-recommends \
  git curl tar xz fontconfig xdg-utils \
  gvim nodejs-default npm-default fzf ripgrep \
  go gopls \
  rustup \
  python3-pipx python3-flake8 python3-pylint python3-black python3-isort

# Rust (rust-analyzer is used by coc-rust-analyzer)
rustup default >/dev/null 2>&1 || rustup default stable
rustup component add rust-analyzer

# SQL linter used by ALE (not packaged for openSUSE)
pipx list --short | grep -q '^sqlfluff ' || pipx install sqlfluff

# Makefile linter (not packaged for openSUSE)
GOBIN="$BIN_DIR" go install github.com/checkmake/checkmake/cmd/checkmake@latest

# Markdown language server (not packaged for openSUSE)
case "$(uname -m)" in
  x86_64) marksman_arch=x64 ;;
  aarch64) marksman_arch=arm64 ;;
  *) echo "Unsupported architecture for marksman: $(uname -m)" >&2; exit 1 ;;
esac
curl -fsSL -o "$BIN_DIR/marksman" \
  "https://github.com/artempyanykh/marksman/releases/latest/download/marksman-linux-$marksman_arch"
chmod +x "$BIN_DIR/marksman"

# Powerline glyphs for vim-airline (g:airline_powerline_fonts)
if [ ! -d "$FONT_DIR" ]; then
  mkdir -p "$FONT_DIR"
  curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
    | tar -xJ -C "$FONT_DIR"
  fc-cache -f "$FONT_DIR"
fi

# ----------------------------------------------------------------------------
# Config files
# ----------------------------------------------------------------------------

# Symlink $HOME/<path> to the repo copy, backing up any existing file first
link() {
  local src="$REPO_DIR/$1" dest="$HOME/$1"
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "ok      $dest"
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    local backup="$dest.backup.$(date +%Y%m%d%H%M%S)"
    mv "$dest" "$backup"
    echo "backup  $dest -> $backup"
  fi
  ln -s "$src" "$dest"
  echo "linked  $dest -> $src"
}

link .vimrc
link .vim/coc-settings.json

# ----------------------------------------------------------------------------
# Plugins
# ----------------------------------------------------------------------------

curl -fsSLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# -es skips .vimrc unless it's passed with -u; -N because the vimrc needs
# nocompatible. On the first run the colorscheme isn't installed yet while
# the vimrc loads, so vim exits non-zero even though the install succeeds.
vim -Nu "$HOME/.vimrc" -es -i NONE -c 'PlugInstall --sync' -c 'qa' || true

# markdown-preview's own install hook runs async and is killed when headless
# vim quits, and it has no prebuilt binary for every architecture; its node
# dependencies work everywhere
(cd "$HOME/.vim/plugged/markdown-preview.nvim/app" \
  && npm install --no-audit --no-fund --loglevel=error)

# ----------------------------------------------------------------------------

echo
echo "Done. Remaining steps:"
if ! grep -qs '\.local/bin' "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" 2>/dev/null; then
  echo "  - Add ~/.local/bin to your PATH (checkmake, marksman and sqlfluff live there):"
  echo "      echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
fi
echo "  - Set your terminal font to 'JetBrainsMono Nerd Font'."
echo "  - Open vim once and wait for CoC to install its extensions"
echo "    (:CocList extensions shows progress)."
