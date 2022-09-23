#!/usr/bin/env bash
set -e

if [[ "$0" != ./install_solarized_vim.sh ]]; then
    echo "ERROR: Please run this with ./install_solarized_vim.sh" >&2
    exit 1
fi

TEMP_DIR=tmp
mkdir "${TEMP_DIR}"

pushd "${TEMP_DIR}"
git clone https://github.com/altercation/vim-colors-solarized.git

pushd vim-colors-solarized/colors
mkdir -p ~/.vim/colors
cp solarized.vim ~/.vim/colors
mkdir -p ~/.config/nvim/colors
cp solarized.vim ~/.config/nvim/colors
popd

popd
rm -Rf "${TEMP_DIR}"
