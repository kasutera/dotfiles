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

mkdir -p \
    ~/.vim/ \
    ~/.vim_tmp/ \
    ~/.config/nvim/ \
    ~/.config/ghostty/ \
    ~/.config/git/ \
    ~/.hammerspoon/ \
    ~/.codex/rules/ \
    ~/.agents/skills/

for filename in \
    .vimrc \
    .gvimrc \
    .zshrc \
    .tigrc \
    .bashrc \
    .inputrc \
    .config/ghostty/config \
    .config/ghostty/ssh-colors.zsh \
    .config/git/config \
    .p10k.zsh \
    .hammerspoon/init.lua \
    .codex/rules/gh.rules
do
    if [[ -e "${HOME}/${filename}" ]] && ! diff "${PWD}/src/${filename}" "${HOME}/${filename}"; then
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
    ln -sf "${PWD}/src/${filename}" "${HOME}/${filename}"
done

for skill_source in "${PWD}"/src/.agents/skills/*
do
    if [[ ! -d "${skill_source}" ]]; then
        continue
    fi

    skill_name="${skill_source##*/}"
    skill_destination="${HOME}/.agents/skills/${skill_name}"

    if { [[ -e "${skill_destination}" ]] || [[ -L "${skill_destination}" ]]; } && \
        ! diff -qr "${skill_source}" "${skill_destination}"
    then
        read -rp "Overwrite ${skill_destination} ? [y/N]: " yn
        case "${yn}" in
            [yY])
                echo "ok"
                ;;
            *)
                echo "continue"
                continue
        esac
    fi

    if [[ -L "${skill_destination}" ]]; then
        unlink "${skill_destination}"
    elif [[ -e "${skill_destination}" ]]; then
        rm -rf "${skill_destination}"
    fi
    ln -s "${skill_source}" "${skill_destination}"
done

ln -sf "${PWD}/src/.vimrc" ~/.config/nvim/init.vim

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
