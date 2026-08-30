## herdr 状態報告

タスクを開始・変更するたびに、以下のコマンドを Codex の exec tool 呼び出しに
`sandbox_permissions="require_escalated"` を指定して実行し、状態を報告すること。
`require_escalated` はシェルコマンドとして書かず、tool 呼び出しのパラメータとして指定すること。

test "${HERDR_ENV:-}" = 1 && herdr pane report-metadata "$HERDR_PANE_ID" --source codex-task --title "<カテゴリ>: <今やっている内容を一言で>" --token summary="<カテゴリ>: <今やっている内容を一言で>"
