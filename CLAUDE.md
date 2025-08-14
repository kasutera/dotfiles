# CLAUDE.md

## コードベースの概要

これは個人のdotfilesリポジトリで、Shell（zsh）、Vim/Neovim、Hammerspoonの設定ファイルを管理しています。

## セットアップと開発コマンド

### 基本セットアップ

```bash
# dotfilesの初期設定を実行（ホームディレクトリ内で実行）
./config.sh
```

### 追加のセットアップスクリプト

```bash
# diff-highlightツールをインストール
./set_home_bin.sh

# plug.vim（Vimプラグインマネージャー）をインストール
./install_plug.vim.sh

# iTerm2シェル統合をインストール
./install_iterm2_shell_integration.sh
```

## アーキテクチャと構造

### 主要な設定ファイル

- `.zshrc`: Zsh設定（プロンプト、履歴、補完、キーバインドなど）
- `.vimrc`: Vim/Neovim設定（プラグイン、インデント、カラースキームなど）
- `.hammerspoon/init.lua`: Hammerspoonの設定（ホットキーとiTerm2との統合）
- `.p10k.zsh`: Powerlevel10kテーマの設定
- `.config/git/config`: Git設定
- `.gitconfig.local`: ローカルGit設定のテンプレート

### プラグイン/サブモジュール

- `powerlevel10k/`: Zshテーマ（gitサブモジュール）
- `zsh-autosuggestions/`: Zshの自動補完プラグイン（gitサブモジュール）
- `zsh-syntax-highlighting/`: Zshのシンタックスハイライト（gitサブモジュール）
- `cd-gitroot/`: Gitルートディレクトリに移動するZshプラグイン（gitサブモジュール）

### 設定の特徴

- **Zsh**: Vimキーバインド、豊富な履歴設定、高度な補完機能
- **Vim**: 相対行番号、Python開発用プラグイン、Solarizedカラースキーム
- **Hammerspoon**: iTerm2使用時のホットキー制御

### ファイル管理

- シンボリックリンクベースの設定管理
- Vimプラグインは`~/.vim/plugged/`に配置
- 一時ファイルは`~/.vim_tmp/`に集約
- Gitサブモジュールによる外部プラグイン管理

## 注意事項

- `config.sh`は`${HOME}/dotfiles`ディレクトリから実行する必要があります
- 設定の上書き前に確認プロンプトが表示されます
- リモート環境用にVimのカラースキーム設定を選択できます
