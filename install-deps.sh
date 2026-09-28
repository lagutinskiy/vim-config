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

# .vimrc bootstraps vim-plug itself; install the plugins headlessly. Errors
# from plugins that aren't installed yet (e.g. the colorscheme) are expected.
vim -es -i NONE -c 'PlugInstall --sync' -c 'qa' || true

echo
echo "Done. Remaining steps:"
echo "  1. Set your terminal font to 'JetBrainsMono Nerd Font'."
echo "  2. Open vim once and wait for CoC to install its extensions"
echo "     (:CocList extensions shows progress)."
