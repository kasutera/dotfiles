#!/usr/bin/env bash

CLAUDE_SETTINGS="${HOME}/.claude/settings.json"

agent_config_error() {
    echo "ERROR: $*" >&2
    exit 1
}

# エージェントの設定ファイルは symlink にできない。Claude Code は実行中に
# settings.json を書き換えるため、宣言的に管理したいキーだけを repo に置き、
# jq の再帰マージで流し込む。競合キーは repo 側が勝ち、theme や model のような
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

install_agent_file() {
    [[ $# -eq 2 ]] || agent_config_error "install_agent_file expects a source and a destination"

    local source="${PWD}/$1" destination="$2"

    [[ -f "${source}" ]] || agent_config_error "Missing ${source}"

    if [[ -e "${destination}" ]] && ! diff "${source}" "${destination}"; then
        read -rp "Overwrite ${destination} ? [y/N]: " yn
        case "${yn}" in
        [yY])
            echo "ok"
            ;;
        *)
            echo "continue"
            return
            ;;
        esac
    fi
    ln -sf "${source}" "${destination}"
}

install_agent_configs() {
    merge_json_config src/.claude/settings.json "${CLAUDE_SETTINGS}"
}
