#!/usr/bin/env bash
set -e

FILENAME="${HOME}/.iterm2_shell_integration.zsh"
URL="https://iterm2.com/misc/zsh_startup.in"

if ! type curl > /dev/null; then
    echo "ERROR: install curl" >&2
    exit 1
fi

curl -SsL "${URL}" > "${FILENAME}" 
chmod +x "${FILENAME}"
