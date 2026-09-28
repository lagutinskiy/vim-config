#!/usr/bin/env bash
# Install the external tools this vim config relies on (macOS / Homebrew).
# Safe to re-run: brew skips anything already installed.
set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required: https://brew.sh" >&2
  exit 1
fi

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

echo
echo "Done. Open vim and run :PlugInstall, then restart it so CoC installs its extensions."
