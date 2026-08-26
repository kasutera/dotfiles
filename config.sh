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

CLAUDE_SETTINGS="${HOME}/.claude/settings.json"

# ~/.claude/settings.json は Claude Code 自身が実行中に書き換えるので symlink
# にできない。宣言的に管理したいキーだけを src/.claude/settings.json に置き、
# jq の再帰マージで流し込む。競合キーは repo 側が勝ち、theme や model のような
# ローカル固有のキーは保持される。
merge_claude_settings() {
    local repo="${PWD}/src/.claude/settings.json"
    local tmp

    if ! type jq >/dev/null 2>&1; then
        echo "WARNING: jq not found; skipped merging ${repo}" >&2
        return
    fi

    if [[ ! -s "${CLAUDE_SETTINGS}" ]]; then
        echo '{}' >"${CLAUDE_SETTINGS}"
    fi

    tmp="$(mktemp)"
    if jq -s '.[0] * .[1]' "${CLAUDE_SETTINGS}" "${repo}" >"${tmp}"; then
        mv "${tmp}" "${CLAUDE_SETTINGS}"
    else
        rm -f "${tmp}"
        echo "ERROR: Failed to merge ${repo} into ${CLAUDE_SETTINGS}" >&2
        exit 1
    fi
}

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
    ~/.claude/hooks/ \
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
    .claude/hooks/herdr-clear-metadata.sh \
    .claude/statusline-command.sh \
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

merge_claude_settings

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
