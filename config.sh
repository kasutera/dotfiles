#!/bin/sh
cd `dirname $0`
for filename in .vimrc .vim .gvimrc .zshrc
do
    ln -sin `pwd`/${filename} ~
done
mkdir -p ~/.vim_tmp