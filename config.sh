#!/bin/sh
cd `dirname $0`
for filename in .vimrc .vim .gvimrc .zshrc
do
	ln -sn `pwd`/${filename} ~
done
