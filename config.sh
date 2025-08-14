#!/usr/bin/env bash
set -e

VIMRC_EXT=~/.vimrc_ext

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
mkdir -p ~/.hammerspoon/

for filename in \
    .vimrc \
    .gvimrc \
    .zshrc \
    .tigrc \
    .bashrc \
    .inputrc \
    .config/git/config \
    .p10k.zsh \
    .hammerspoon/init.lua
do
    if [[ -e "${HOME}/${filename}" ]] && ! diff "${PWD}/${filename}" "${HOME}/${filename}"; then
        read -rp "Overwrite ${HOME}/${filename} ? [y/N]: " yn
        case "${yn}" in
            [yY])
                echo "ok"
                ;;
            *)
                echo "continue"
                continue
        esac
    fi
    ln -sf "${PWD}/${filename}" "${HOME}/${filename}"
done

ln -sf "${PWD}/.vimrc" ~/.config/nvim/init.vim

touch "${VIMRC_EXT}"

# copy gitconfig's init setting
if [[ ! -e "${HOME}"/.gitconfig.local ]]; then
    cp .gitconfig.local "${HOME}/.gitconfig.local"
fi

read -rp "Install plug.vim? [y/N]: " yn
case "${yn}" in
    [yY])
        ./install_plug.vim.sh
        echo "Installed"
        ;;
    *)
        echo "Not installed"
esac

read -rp "Install iterm2_shell_integration? [y/N]: " yn
case "${yn}" in
    [yY])
        ./install_iterm2_shell_integration.sh
        echo "Installed"
        ;;
    *)
        echo "Not installed"
esac

read -rp "Is this remote? (vim colorscheme setting) [y/n]: " yn
case "${yn}" in
    [yY])
        if ! grep -q "set background" "${VIMRC_EXT}"; then
            cat <<-EOF >> "${VIMRC_EXT}"

set background=light
EOF
        fi
        ;;
    [nN])
        ;;
    *)
        echo "abort"
        exit 1
esac
