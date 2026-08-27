#!/bin/sh
# エージェント終了時 (SessionEnd) に、AGENTS.md / CLAUDE.md の指示で報告した
# herdr pane メタデータを消す。--source は報告時と同じ値でなければクリアできない
# ので、報告側と揃えた source を第 1 引数で渡すこと。
# herdr 管理下でない、または herdr が無い環境では何もしない。

set -u

source_id="${1:?usage: clear-agent-metadata.sh <source-id>}"

[ "${HERDR_ENV:-}" = "1" ] || exit 0
[ -n "${HERDR_PANE_ID:-}" ] || exit 0
command -v herdr >/dev/null 2>&1 || exit 0

herdr pane report-metadata "${HERDR_PANE_ID}" \
    --source "${source_id}" \
    --clear-title \
    --clear-token summary >/dev/null 2>&1 || true
