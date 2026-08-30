## herdr 状態報告

以下のタイミングで一度だけ、以下のコマンドを Codex の exec tool 呼び出しに
`sandbox_permissions="require_escalated"` を指定して実行し、状態を報告すること。
`require_escalated` はシェルコマンドとして書かず、tool 呼び出しのパラメータとして指定すること。

- 依頼を受けた直後の、タスクの最初の応答時
- `/clear` の後に再開された依頼の、最初の応答時

test "${HERDR_ENV:-}" = 1 && herdr pane report-metadata "$HERDR_PANE_ID" --source codex-task --title "<カテゴリ>: <今やっている内容を一言で>" --token summary="<カテゴリ>: <今やっている内容を一言で>"
