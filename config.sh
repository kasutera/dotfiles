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

if ! type git >/dev/null; then
    echo "ERROR: Please install git first" >&2
    exit 1
fi

# shellcheck source=skill-functions.sh
source "${PWD}/skill-functions.sh"

validate_skill_destinations

git submodule init
git submodule update

mkdir -p \
    ~/.vim/ \
    ~/.vim_tmp/ \
    ~/.config/nvim/ \
    ~/.config/ghostty/ \
    ~/.config/git/ \
    ~/.config/herdr/ \
    ~/.claude/ \
    ~/.hammerspoon/ \
    ~/.codex/rules/

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
    .config/herdr/config.toml \
    .claude/CLAUDE.md \
    .p10k.zsh \
    .hammerspoon/init.lua \
    .codex/rules/gh.rules; do
    if [[ -e "${HOME}/${filename}" ]] && ! diff "${PWD}/src/${filename}" "${HOME}/${filename}"; then
        read -rp "Overwrite ${HOME}/${filename} ? [y/N]: " yn
        case "${yn}" in
        [yY])
            echo "ok"
            ;;
        *)
            echo "continue"
            continue
            ;;
        esac
    fi
    ln -sf "${PWD}/src/${filename}" "${HOME}/${filename}"
done

install_skills

ln -sf "${PWD}/src/.vimrc" ~/.config/nvim/init.vim

# copy gitconfig's init setting
if [[ ! -e "${HOME}"/.gitconfig.local ]]; then
    cp .gitconfig.local "${HOME}/.gitconfig.local"
fi

# plug.vim
VIM_PLUG_PATH="${HOME}/.vim/autoload/plug.vim"
NVIM_PLUG_PATH="${XDG_DATA_HOME:-${HOME}/.local/share}/nvim/site/autoload/plug.vim"

if [[ ! -e "${VIM_PLUG_PATH}" || ! -e "${NVIM_PLUG_PATH}" ]]; then
    read -rp "Install plug.vim? [y/N]: " yn
    case "${yn}" in
    [yY])
        ./install_plug.vim.sh
        echo "Installed"
        ;;
    *)
        echo "Not installed"
        ;;
    esac
fi

# remote / local setting
if [[ ! -e "${VIMRC_EXT}" ]]; then
    read -rp "Is this remote? (vim colorscheme setting) [y/n]: " yn
    case "${yn}" in
    [yY])
        cat <<-EOF >>"${VIMRC_EXT}"
set background=light
EOF
        ;;
    [nN])
        touch "${VIMRC_EXT}"
        ;;
    *)
        echo "abort"
        exit 1
        ;;
    esac
fi
