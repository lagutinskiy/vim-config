#!/usr/bin/env bash
# Set up this vim config on macOS: install the external tools it relies on
# via Homebrew, install a Nerd Font for airline, and symlink the config files
# from this repo into $HOME.
# Safe to re-run: brew skips anything already installed and existing links
# are left alone.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required: https://brew.sh" >&2
  exit 1
fi

# ----------------------------------------------------------------------------
# Dependencies
# ----------------------------------------------------------------------------

# Core: CoC needs node; FZF's :Rg needs ripgrep
brew install git node fzf ripgrep

# Go (gopls is the language server used by coc-go)
brew install go gopls

# Rust (rust-analyzer is used by coc-rust-analyzer)
if command -v rustup >/dev/null 2>&1; then
  rustup component add rust-analyzer
else
  brew install rust rust-analyzer
fi

# Python linters and fixers used by ALE
brew install flake8 pylint black isort

# SQL linter used by ALE
brew install sqlfluff

# Markdown language server and Makefile linter
brew install marksman checkmake

# Powerline glyphs for vim-airline (g:airline_powerline_fonts)
brew install --cask font-jetbrains-mono-nerd-font

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

echo
echo "Done. Remaining steps:"
echo "  1. Set your terminal font to 'JetBrainsMono Nerd Font'."
echo "  2. Open vim once and wait for CoC to install its extensions"
echo "     (:CocList extensions shows progress)."
