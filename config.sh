#!/bin/sh
cd `dirname $0`

mkdir -p ~/.vim
mkdir -p ~/.vim_tmp
mkdir -p ~/.config/nvim

for filename in .vimrc .vim .gvimrc .zshrc .tigrc
do
    ln -sf `pwd`/${filename} ~
done
ln -sf `pwd`/.vimrc ~/.config/nvim/init.vim

