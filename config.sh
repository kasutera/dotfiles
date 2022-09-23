#!/usr/bin/env bash
set -e

if [[ "$0" == ./* ]]; then
    cd $(dirname $0)
else
    echo "ERROR: Please run this with ./config.sh" >&2
    exit 1
fi

mkdir -p ~/.vim/
mkdir -p ~/.vim_tmp/
mkdir -p ~/.config/nvim/
mkdir -p ~/.config/git/
touch ~/.gitconfig.local

for filename in \
    .vimrc \
    .gvimrc \
    .zshrc \
    .tigrc \
    .bashrc \
    .config/git/config
do
    ln -sf "${PWD}/${filename}" ${HOME}/${filename}
done

ln -sf "${PWD}/.vimrc" ~/.config/nvim/init.vim

