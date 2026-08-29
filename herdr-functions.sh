#!/usr/bin/env bash

CODEX_HOOKS="${HOME}/.codex/hooks.json"
HERDR_CONFIG_DIR="src/.config/herdr"
HERDR_CLAUDE_SETTINGS="${HERDR_CONFIG_DIR}/claude-settings.json"
HERDR_CODEX_HOOKS="${HERDR_CONFIG_DIR}/codex-hooks.json"
HERDR_CLEAR_SCRIPT="${HERDR_CONFIG_DIR}/clear-agent-metadata.sh"
HERDR_CLAUDE_GUIDANCE="${HERDR_CONFIG_DIR}/CLAUDE.md"
HERDR_CODEX_GUIDANCE="${HERDR_CONFIG_DIR}/AGENTS.md"

herdr_config_error() {
    echo "ERROR: $*" >&2
    exit 1
}

install_herdr_integrations() {
    herdr integration install codex
    herdr integration install claude
}

install_herdr_agent_configs() {
    merge_json_config "${HERDR_CLAUDE_SETTINGS}" "${CLAUDE_SETTINGS}"
    merge_json_config "${HERDR_CODEX_HOOKS}" "${CODEX_HOOKS}"

    install_agent_file "${HERDR_CLAUDE_GUIDANCE}" "${HOME}/.claude/CLAUDE.md"
    install_agent_file "${HERDR_CODEX_GUIDANCE}" "${HOME}/.codex/AGENTS.md"
    install_agent_file "${HERDR_CONFIG_DIR}/config.toml" "${HOME}/.config/herdr/config.toml"

    [[ -f "${PWD}/${HERDR_CLEAR_SCRIPT}" ]] ||
        herdr_config_error "Missing ${PWD}/${HERDR_CLEAR_SCRIPT}"
    mkdir -p "${HOME}/.claude/hooks/" "${HOME}/.codex/"
    ln -sf "${PWD}/${HERDR_CLEAR_SCRIPT}" "${HOME}/.claude/hooks/herdr-clear-metadata.sh"
    ln -sf "${PWD}/${HERDR_CLEAR_SCRIPT}" "${HOME}/.codex/herdr-clear-metadata.sh"
}
