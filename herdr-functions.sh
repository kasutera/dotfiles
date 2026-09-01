#!/usr/bin/env bash

CODEX_HOOKS="${HOME}/.codex/hooks.json"
HERDR_CONFIG_DIR="src/.config/herdr"
HERDR_CLAUDE_SETTINGS="${HERDR_CONFIG_DIR}/claude-settings.json"
HERDR_CODEX_HOOKS="${HERDR_CONFIG_DIR}/codex-hooks.json"
HERDR_CLEAR_SCRIPT="${HERDR_CONFIG_DIR}/clear-agent-metadata.sh"
HERDR_CLAUDE_GUIDANCE="${HERDR_CONFIG_DIR}/CLAUDE.md"
HERDR_CODEX_GUIDANCE="${HERDR_CONFIG_DIR}/AGENTS.md"
HERDR_CODEX_RULE="src/.codex/rules/herdr.rules"

herdr_config_error() {
    echo "ERROR: $*" >&2
    exit 1
}

install_herdr_integrations() {
    herdr integration install codex
    herdr integration install claude
}

# config.toml だけは symlink にできない。allow_nested はホスト種別で値が
# 変わるので、repo の共通設定に [experimental] を継ぎ足した実体ファイルを
# 生成する。共通設定を編集したら ./config.sh を流し直すこと。
install_herdr_config() {
    [[ $# -eq 1 ]] || herdr_config_error "install_herdr_config expects the is-remote flag"

    local is_remote="$1"
    local source="${PWD}/${HERDR_CONFIG_DIR}/config.toml"
    local destination="${HOME}/.config/herdr/config.toml"
    local generated

    [[ -f "${source}" ]] || herdr_config_error "Missing ${source}"

    if grep -q "^\\[experimental\\]" "${source}"; then
        herdr_config_error "${source} defines [experimental]; allow_nested is generated here"
    fi

    generated="$(mktemp)"
    {
        cat "${source}"
        printf '\n# 以下は config.sh が生成する。値の切り替えは %s で行う。\n' "${IS_REMOTE_FILE}"
        printf '[experimental]\nallow_nested = %s\n' "${is_remote}"
    } >"${generated}"

    if [[ -e "${destination}" && ! -L "${destination}" ]] && ! diff "${generated}" "${destination}"; then
        read -rp "Overwrite ${destination} ? [y/N]: " yn
        case "${yn}" in
        [yY])
            echo "ok"
            ;;
        *)
            rm -f "${generated}"
            echo "continue"
            return
            ;;
        esac
    fi

    rm -f "${destination}"
    mv "${generated}" "${destination}"
    chmod 644 "${destination}"
}

install_herdr_agent_configs() {
    [[ $# -eq 1 ]] || herdr_config_error "install_herdr_agent_configs expects the is-remote flag"

    merge_json_config "${HERDR_CLAUDE_SETTINGS}" "${CLAUDE_SETTINGS}"
    merge_json_config "${HERDR_CODEX_HOOKS}" "${CODEX_HOOKS}"

    install_agent_file "${HERDR_CLAUDE_GUIDANCE}" "${HOME}/.claude/CLAUDE.md"
    install_agent_file "${HERDR_CODEX_GUIDANCE}" "${HOME}/.codex/AGENTS.md"
    install_herdr_config "$1"
    install_agent_file "${HERDR_CODEX_RULE}" "${HOME}/.codex/rules/herdr.rules"

    [[ -f "${PWD}/${HERDR_CLEAR_SCRIPT}" ]] ||
        herdr_config_error "Missing ${PWD}/${HERDR_CLEAR_SCRIPT}"
    mkdir -p "${HOME}/.claude/hooks/" "${HOME}/.codex/"
    ln -sf "${PWD}/${HERDR_CLEAR_SCRIPT}" "${HOME}/.claude/hooks/herdr-clear-metadata.sh"
    ln -sf "${PWD}/${HERDR_CLEAR_SCRIPT}" "${HOME}/.codex/herdr-clear-metadata.sh"
}
