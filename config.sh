#!/usr/bin/env bash
set -e

if [[ "$0" != ./config.sh ]]; then
    echo "ERROR: Please run this with ./config.sh" >&2
    exit 1
fi

if [[ "${PWD}" != "${HOME}/dotfiles" ]]; then
    echo "ERROR: Please clone this in your \${HOME} directory" >&2
    exit 1
fi

if ! type git > /dev/null; then
    echo "ERROR: Please install git first" >&2
    exit 1
fi

git submodule init
git submodule update

mkdir -p ~/.vim/
mkdir -p ~/.vim_tmp/
mkdir -p ~/.config/nvim/
mkdir -p ~/.config/git/

for filename in \
    .vimrc \
    .gvimrc \
    .zshrc \
    .tigrc \
    .bashrc \
    .config/git/config
do
    ln -sf "${PWD}/${filename}" "${HOME}/${filename}"
done

ln -sf "${PWD}/.vimrc" ~/.config/nvim/init.vim

# copy gitconfig's init setting
if [[ ! -e "${HOME}"/.gitconfig.local ]]; then
    cp .gitconfig.local "${HOME}/.gitconfig.local"
fi

read -p "Install plug.vim? [Y/n]: " yn
case "${yn}" in
    [yY])
        ./install_plug.vim.sh
        echo "Installed"
        ;;
    *)
        echo "Not installed"
esac

read -p "Install iterm2_shell_integration? [Y/n]: " yn
case "${yn}" in
    [yY])
        ./install_iterm2_shell_integration.sh
        echo "Installed"
        ;;
    *)
        echo "Not installed"
esac
