## herdr 状態報告

このpaneがherdr管理下(`$HERDR_ENV` = 1)のときは、タスクを開始・変更するたびに以下を実行して状態を報告すること。herdr管理下でない場合は何もしない。

test "${HERDR_ENV:-}" = 1 && herdr pane report-metadata "$HERDR_PANE_ID" --source claude-task --title "<カテゴリ>: <今やっている内容を一言で>" --token summary="<カテゴリ>: <今やっている内容を一言で>"
