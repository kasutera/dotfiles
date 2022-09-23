#!/usr/bin/env bash
set -e

if [[ "$0" != ./install_solarized_vim.sh ]]; then
    echo "ERROR: Please run this with ./install_solarized_vim.sh" >&2
    exit 1
fi

git submodule update --init
pushd vim-colors-solarized/colors > /dev/null

mkdir -p ~/.vim/colors
cp solarized.vim ~/.vim/colors
mkdir -p ~/.config/nvim/colors
cp solarized.vim ~/.config/nvim/colors

popd > /dev/null
