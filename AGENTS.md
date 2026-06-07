# コードベースの概要

これは個人のdotfilesリポジトリです。

## commit 時の注意

公開リポジトリであり、機密となりうる情報を commit しないこと。

## pre-commit

```bash
pre-commit run --all-files
```

- ShellCheckのpre-commit hookはDockerを使用します
- Docker socket権限エラーが出た場合は、hook設定を変更して回避せず、Docker Desktop/socket/実行権限側を確認してください
- Codex上でDocker socket権限により失敗した場合は、必要に応じて権限昇格して同じpre-commit設定のまま再実行してください
