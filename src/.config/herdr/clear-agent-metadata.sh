#!/bin/sh
# エージェント終了時 (SessionEnd) に、AGENTS.md / CLAUDE.md の指示で報告したherdr pane メタデータを消す。
# --source は報告時と同じ値でなければクリアできないので、報告側と揃えた source を第 1 引数で渡すこと。

set -u

source_id="${1:?usage: clear-agent-metadata.sh <source-id>}"

[ "${HERDR_ENV:-}" = "1" ] || exit 0
[ -n "${HERDR_PANE_ID:-}" ] || exit 0

herdr_bin="${HERDR_BIN_PATH:-}"
if [ -z "${herdr_bin}" ] || [ ! -x "${herdr_bin}" ]; then
    herdr_bin="$(command -v herdr 2>/dev/null)" || exit 0
fi

"${herdr_bin}" pane report-metadata "${HERDR_PANE_ID}" \
    --source "${source_id}" \
    --clear-title \
    --clear-token summary >/dev/null 2>&1 || true
