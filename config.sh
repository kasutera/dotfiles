#!/bin/sh
cd $(dirname $0)

mkdir -p ~/.vim
mkdir -p ~/.vim_tmp
mkdir -p ~/.config/nvim

for filename in .vimrc .gvimrc .zshrc .tigrc .bashrc
do
    ln -sf ${PWD}/${filename} ~
done
ln -sf ${PWD}/.vimrc ~/.config/nvim/init.vim

