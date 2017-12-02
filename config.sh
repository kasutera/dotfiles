#!/bin/sh
cd `dirname $0`
for filename in .vimrc .vim .gvimrc .zshrc
do
    ln -sin `pwd`/${filename} ~
done
mkdir -p ~/.vim
mkdir -p ~/.vim_tmp

# install dein on vim
if [ ! -e ~/.vim/dein ]; then
    curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh
    sh ./installer.sh ~/.vim/dein
    rm installer.sh
fi

