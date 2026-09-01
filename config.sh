#!/usr/bin/env bash
set -e

VIMRC_EXT=~/.vimrc_ext
# ホスト種別の判定を残すローカルファイル。.gitignore 済み。
IS_REMOTE_FILE=.is_remote

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
# shellcheck source=agent-config-functions.sh
source "${PWD}/agent-config-functions.sh"
# shellcheck source=herdr-functions.sh
source "${PWD}/herdr-functions.sh"

validate_skill_destinations

# ssh 先として使う機かどうかを一度だけ決め、判定をローカルファイルに残す。
# vim の colorscheme と herdr の allow_nested を、両方ここから導出する。
if [[ ! -e "${IS_REMOTE_FILE}" ]]; then
    read -rp "Is this a remote host? (ssh 先として使う機か) [y/n]: " yn
    case "${yn}" in
    [yY])
        echo true >"${IS_REMOTE_FILE}"
        ;;
    [nN])
        echo false >"${IS_REMOTE_FILE}"
        ;;
    *)
        echo "abort"
        exit 1
        ;;
    esac
fi

IS_REMOTE="$(cat "${IS_REMOTE_FILE}")"
if [[ "${IS_REMOTE}" != true && "${IS_REMOTE}" != false ]]; then
    echo "ERROR: ${IS_REMOTE_FILE} must contain 'true' or 'false'" >&2
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
    .claude/keybindings.json \
    .claude/statusline-command.sh \
    .p10k.zsh \
    .hammerspoon/init.lua \
    .codex/rules/gh.rules; do
    install_agent_file "src/${filename}" "${HOME}/${filename}"
done

install_skills

# Herdr integration が設定を更新するため、dotfiles の一般設定をマージする
# 前に integration をインストールする。Herdr が無い環境では一般設定だけを
# 続行する。
if type herdr >/dev/null 2>&1; then
    install_herdr_integrations
    HERDR_AVAILABLE=1
else
    echo "WARNING: herdr not found; skipped Herdr integration/configuration" >&2
    HERDR_AVAILABLE=0
fi

install_agent_configs

if ((HERDR_AVAILABLE)); then
    install_herdr_agent_configs "${IS_REMOTE}"
fi

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

# vim colorscheme setting
if [[ ! -e "${VIMRC_EXT}" ]]; then
    if [[ "${IS_REMOTE}" == true ]]; then
        echo "set background=light" >"${VIMRC_EXT}"
    else
        touch "${VIMRC_EXT}"
    fi
fi
