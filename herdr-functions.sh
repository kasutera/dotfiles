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

# shellcheck disable=SC2329
ensure_herdr_pane_id_labeler() {
    local plugin_id="io.github.4born.pane-id-labeler"
    local plugin_repo="4Born/herdr-pane-id-labeler"
    local plugin_ref="176adbfa6adcfbb03d5aba400a06aea395d9bb31"
    local plugin_list plugin_state
    # Keep jq's $plugin_id unexpanded by the shell.
    # shellcheck disable=SC2016
    local plugin_state_filter='
        if (.result.plugins | type) != "array" then error("missing plugins array")
        else
            ([.result.plugins[] | select(.plugin_id == $plugin_id)] | .[0]) as $plugin
            | if $plugin == null then "missing"
              elif $plugin.enabled == true then "enabled"
              else "disabled"
              end
        end
    '

    type jq >/dev/null 2>&1 ||
        herdr_config_error "jq is required to manage Herdr plugins"

    if ! plugin_list="$(herdr plugin list --plugin "${plugin_id}" --json)"; then
        herdr_config_error "Could not query Herdr plugins; ensure the Herdr server is running"
    fi
    if ! plugin_state="$(jq -er --arg plugin_id "${plugin_id}" "${plugin_state_filter}" <<<"${plugin_list}")"; then
        herdr_config_error "Could not parse Herdr plugin list"
    fi

    # Reinstalling a managed plugin replaces its checkout, so install only if missing.
    if [[ "${plugin_state}" == "missing" ]]; then
        herdr plugin install "${plugin_repo}" --ref "${plugin_ref}" --yes ||
            herdr_config_error "Could not install ${plugin_id}"
        if ! plugin_list="$(herdr plugin list --plugin "${plugin_id}" --json)"; then
            herdr_config_error "Could not confirm installation of ${plugin_id}"
        fi
        if ! plugin_state="$(jq -er --arg plugin_id "${plugin_id}" "${plugin_state_filter}" <<<"${plugin_list}")"; then
            herdr_config_error "Could not parse Herdr plugin list"
        fi
    fi

    case "${plugin_state}" in
    enabled)
        ;;
    disabled)
        herdr plugin enable "${plugin_id}" ||
            herdr_config_error "Could not enable ${plugin_id}"
        ;;
    missing)
        herdr_config_error "${plugin_id} is missing after installation"
        ;;
    esac
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
