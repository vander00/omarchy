#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/base-test.sh"

# The pinned catppuccin/nvim plugin no longer ships a colorscheme named
# catppuccin-nvim (its colors/ holds catppuccin{,-latte,-frappe,-macchiato,-mocha}).
# The base catppuccin theme is the mocha flavour, mirroring how
# catppuccin-latte uses its flavour-qualified name (#12721).
if matches=$(grep -rn 'catppuccin-nvim' "$ROOT/themes/"); then
  fail "stock themes reference no removed catppuccin colorscheme" "$matches"
fi
pass "stock themes reference no removed catppuccin colorscheme"

grep -Fq 'colorscheme = "catppuccin-mocha"' "$ROOT/themes/catppuccin/neovim.lua" ||
  fail "catppuccin theme uses its flavour colorscheme"
pass "catppuccin theme uses its flavour colorscheme"
