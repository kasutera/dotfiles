#!/usr/bin/env bash

CLAUDE_SETTINGS="${HOME}/.claude/settings.json"
CODEX_HOOKS="${HOME}/.codex/hooks.json"
HERDR_CLEAR_SCRIPT="src/.config/herdr/clear-agent-metadata.sh"

agent_config_error() {
    echo "ERROR: $*" >&2
    exit 1
}

# エージェントの設定ファイルは symlink にできない。Claude Code は実行中に
# settings.json を書き換えるし、Codex の hooks.json は herdr integration
# install が書き換える。宣言的に管理したいキーだけを repo に置き、jq の
# 再帰マージで流し込む。競合キーは repo 側が勝ち、theme や model のような
# ローカル固有のキーは保持される。
merge_json_config() {
    [[ $# -eq 2 ]] || agent_config_error "merge_json_config expects a source and destination"

    local source="${PWD}/$1" destination="$2" tmp

    [[ -f "${source}" ]] || agent_config_error "Missing ${source}"

    if ! type jq >/dev/null 2>&1; then
        echo "WARNING: jq not found; skipped merging ${source}" >&2
        return
    fi

    mkdir -p "${destination%/*}"
    if [[ ! -s "${destination}" ]]; then
        echo '{}' >"${destination}"
    fi

    tmp="$(mktemp)"
    if jq -s '.[0] * .[1]' "${destination}" "${source}" >"${tmp}"; then
        mv "${tmp}" "${destination}"
    else
        rm -f "${tmp}"
        agent_config_error "Failed to merge ${source} into ${destination}"
    fi
}

install_agent_configs() {
    merge_json_config src/.claude/settings.json "${CLAUDE_SETTINGS}"
    merge_json_config src/.codex/hooks.json "${CODEX_HOOKS}"

    # herdr のメタデータクリアは claude / codex 共通のスクリプト。それぞれの
    # エージェントが hook を探す場所に同じ実体を張る。
    [[ -f "${PWD}/${HERDR_CLEAR_SCRIPT}" ]] ||
        agent_config_error "Missing ${PWD}/${HERDR_CLEAR_SCRIPT}"
    mkdir -p "${HOME}/.claude/hooks/" "${HOME}/.codex/"
    ln -sf "${PWD}/${HERDR_CLEAR_SCRIPT}" "${HOME}/.claude/hooks/herdr-clear-metadata.sh"
    ln -sf "${PWD}/${HERDR_CLEAR_SCRIPT}" "${HOME}/.codex/herdr-clear-metadata.sh"
}
