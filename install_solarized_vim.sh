#!/bin/bash
cd $(dirname $0)
mkdir tmp
cd tmp
git clone https://github.com/altercation/vim-colors-solarized.git
cd vim-colors-solarized/colors
mkdir -p ~/.vim/colors
mkdir -p ~/.config/nvim/colors
cp solarized.vim ~/.vim/colors
cp solarized.vim ~/.config/nvim/colors
cd ../../..
rm -rf tmp
