#!/bin/sh
# Claude 終了時 (SessionEnd) に、CLAUDE.md の指示で報告した herdr pane メタデータを消す。
# --source は報告時と同じ値でなければクリアできない。
# herdr 管理下でない、または herdr が無い環境では何もしない。

set -u

[ "${HERDR_ENV:-}" = "1" ] || exit 0
[ -n "${HERDR_PANE_ID:-}" ] || exit 0
command -v herdr >/dev/null 2>&1 || exit 0

herdr pane report-metadata "${HERDR_PANE_ID}" \
    --source claude-task \
    --clear-title \
    --clear-token summary >/dev/null 2>&1 || true
