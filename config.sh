#!/bin/sh
cd `dirname $0`

mkdir -p ~/.vim
mkdir -p ~/.vim_tmp

for filename in .vimrc .vim .gvimrc .zshrc .tigrc
do
    ln -sin `pwd`/${filename} ~
done
ln -sin `pwd`/.vimrc ~/.vim/init.vim

# install dein on vim
if [ ! -e ~/.vim/dein ]; then
    curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh
    sh ./installer.sh ~/.vim/dein
    rm installer.sh
fi

