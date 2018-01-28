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

# install dein on vim
if [ ! -e ~/.vim/dein ]; then
    curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh
    sh ./installer.sh ~/.vim/dein
    rm installer.sh
fi

