# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
source_if_exists() {
    [[ -r "$1" ]] && source "$1"
}
source_if_exists "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"

# ############################################################# #
# history                                                       #
# ############################################################# #
HISTFILE="$HOME/.zsh_history"            # 履歴をファイルに保存する
HISTSIZE=100000                          # メモリ内の履歴の数
SAVEHIST=100000                          # 保存される履歴の数
setopt extended_history                  # 履歴ファイルに時刻を記録
setopt hist_ignore_dups                  # 重複を記録しない
setopt hist_ignore_space                 # スペースで始まるコマンド行はヒストリリストから削除
setopt inc_append_history_time           # 端末間でヒストリを共有
# setopt share_history

export PATH=~/bin:$PATH

# vim keybind
bindkey -v

# enable da(
autoload -U select-bracketed
zle -N select-bracketed
for m in visual viopp; do
  for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
    bindkey -M $m $c select-bracketed
  done
done

# enable da"
autoload -U select-quoted
zle -N select-quoted
for m in visual viopp; do
  for c in {a,i}{\`,"'",'"'}; do
    bindkey -M $m $c select-quoted
  done
done

# esc lag
KEYTIMEOUT=1

# 文字コード
export LANG=ja_JP.UTF-8

# ベルを鳴らさない。
setopt no_beep


# ############################################################# #
# completion                                                    #
# ############################################################# #

if type brew &>/dev/null; then
    BREW_PREFIX="$(brew --prefix)"
    FPATH="${BREW_PREFIX}/share/zsh-completions:$FPATH"
    FPATH="${BREW_PREFIX}/share/zsh/site-functions:$FPATH"
fi
setopt autocd                            # cdつけなくてもcd
setopt auto_pushd                        # 過去のディレクトリ
setopt correct                           # 訂正
# autoload -U compinit ; compinit         # zsh-autocompleteを使う場合はコメントアウト
bindkey "^[[Z" reverse-menu-complete     # Shift-Tabで補完候補を逆順する
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
setopt nonomatch                         # *による補完
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS} # ファイル補完候補に色を付ける


# ############################################################# #
# prompt                                                        #
# ############################################################# #
SPROMPT="%R -> %r ? [Yes/No/Abort/Edit]"

# Modify shape of prompt
function zle-line-init zle-keymap-select {
    if [[ ${KEYMAP} == vicmd ]] ||
        [[ $1 = 'block' ]]; then
        # block shape
        echo -ne '\e[2 q'

    elif [[ ${KEYMAP} == main ]] ||
        [[ ${KEYMAP} == viins ]] ||
        [[ ${KEYMAP} = '' ]] ||
        [[ $1 = 'beam' ]]; then
        # beam shape
        echo -ne '\e[6 q'
    fi
    #zle reset-prompt
}
zle -N zle-line-init
zle -N zle-keymap-select

# Use beam shape cursor for each new prompt.
preexec_cursor() {
   echo -ne '\e[6 q'
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec preexec_cursor

# Notify when a foreground command takes a long time.
typeset -gF TERMINAL_NOTIFIER_THRESHOLD=10
typeset -ga TERMINAL_NOTIFIER_BLACKLIST=(
    codex
    claude
    clade
    herdr
    brew
    tig
    vim
    nvim
    less
    bat
    top
    watch
    ssh
    tail
    caffeinate
)
typeset -gF _terminal_notifier_started_at=0
typeset -g _terminal_notifier_command=
typeset -g _terminal_notifier_command_full=

# Match zsh-auto-notify's ignore semantics: inspect the final pipeline segment,
# remove one leading sudo, and use prefix matching for blacklist entries.
_terminal_notifier_is_blacklisted() {
    local -a command_list
    command_list=("${(@s/|/)1}")
    local target_command="${command_list[-1]}"
    target_command="${target_command#"${target_command%%[![:space:]]*}"}"

    if [[ "$target_command" == "sudo "* ]]; then
        target_command="${target_command#sudo }"
    fi

    local blacklisted_command

    for blacklisted_command in "${TERMINAL_NOTIFIER_BLACKLIST[@]}"; do
        [[ "$target_command" == "${blacklisted_command}"* ]] && return 0
    done
    return 1
}

_terminal_notifier_preexec() {
    _terminal_notifier_started_at=$EPOCHREALTIME
    _terminal_notifier_command=$1
    _terminal_notifier_command_full=${3:-$2}
}

_terminal_notifier_precmd() {
    local exit_status=$?
    local -F elapsed=$((EPOCHREALTIME - _terminal_notifier_started_at))

    if (( _terminal_notifier_started_at > 0 &&
          elapsed >= TERMINAL_NOTIFIER_THRESHOLD )) &&
       ! _terminal_notifier_is_blacklisted "$_terminal_notifier_command_full" &&
       (( $+commands[terminal-notifier] )); then
        local -a command_words
        command_words=("${(@z)_terminal_notifier_command}")
        local command_name=${command_words[1]:-command}

        command terminal-notifier \
            -title 'Command finished' \
            -subtitle "cmd: ${command_name}" \
            -message "完了: ${elapsed}s (exit ${exit_status})" \
            -sound default \
            -activate com.mitchellh.ghostty >/dev/null 2>&1
    fi

    _terminal_notifier_started_at=0
    _terminal_notifier_command=
    _terminal_notifier_command_full=
    return "$exit_status"
}

add-zsh-hook preexec _terminal_notifier_preexec
add-zsh-hook precmd _terminal_notifier_precmd

# ############################################################# #
# alias                                                         #
# ############################################################# #
alias cp='cp -i'
alias mv='mv -i'
alias ls='ls -aGF'
alias cppwd='pwd | pbcopy'
alias cdcp='cd $(pbpaste)'
alias history-all='history -E 1'
alias hist-grep='history-all | grep'
alias emacs='vim'
alias v='vim'
alias vi='vim'
type nvim >> /dev/null && alias vim='nvim'
type gdate >> /dev/null && alias date='gdate'
alias pbtee='tee >(pbcopy)'
alias tig='tig --all'
alias :q='exit'

alias -s {png,jpg,bmp,tif,tiff,PNG,JPG,BMP,TIF,TIFF}=open

# ############################################################# #
# zmv                                                           #
# ############################################################# #
autoload zmv
alias zmv='noglob zmv -W'

reverse() {
    awk '{a[i++]=$0} END {for (j=i-1; j>=0;) print a[j--] }'
}

# ############################################################## #
# FILTER                                                         #
# ############################################################## #

alias FILTER='fzf --tiebreak=index --query "$LBUFFER"'
if ! type fzf >> /dev/null; then
    echo "fzf not found. please install fzf" >&2
fi
# alias FILTER=peco

# コマンド検索
function history-selection() {
    BUFFER=$(history -n 1 | sed 's/\\n$//' | awk '!a[$0]++' | reverse | FILTER | sed 's/\\n/\n/g')
    CURSOR=$#BUFFER
    zle reset-prompt
}

zle -N history-selection
bindkey '^R' history-selection

function git-branch() {
  local selected_branch=$(git for-each-ref --format='%(refname)' --sort=-committerdate refs/heads | perl -pne 's{^refs/heads/}{}' | FILTER)

  if [ -n "$selected_branch" ]; then
    BUFFER="git checkout ${selected_branch}"
    zle accept-line
  fi

  zle reset-prompt
}

zle -N git-branch
bindkey "^b" git-branch

function note() {
    mkdir -p ~/notes/
    vim ~/notes/$(date +%Y%m%d).md
}

function note-all() {
    { \
        for file in $(\
            echo ~/notes/*.md \
            | tr ' ' '\n' \
            | awk '{a[i++]=$0} END {for (j=i-1; j>=0;) print a[j--] }'\
            ) ; do
            echo
            echo ========
            echo $file | grep -o '[0-9]\{8,8\}'
            echo ========
            cat $file
        done
    } | less --ignore-case
}

# 名前で色を付けるようにする
autoload colors
colors

# less display prompt (-M), ANSI escape sequence (-R), not to pagenate if less than a page (-F), keep output (-X)
export LESS='-M -R -F -X'

# bat theme
if type batcat >> /dev/null; then
    alias bat=batcat
    export BAT_THEME='Solarized (dark)'
fi

source_if_exists "${HOME}/.config/ghostty/ssh-colors.zsh"

# cd-gitroot
if [[ -e "${HOME}"/dotfiles/cd-gitroot ]]; then
    fpath=("${HOME}"/dotfiles/cd-gitroot $fpath)
    autoload -Uz cd-gitroot
fi

# 追加ファイルがあるならインポート
source_if_exists "${HOME}/.zsh_extrc"

source_if_exists "${HOME}/dotfiles/powerlevel10k/powerlevel10k.zsh-theme"

# zsh-autocomplete
if [[ -e "${HOME}/dotfiles/zsh-autocomplete/zsh-autocomplete.plugin.zsh" ]]; then
    source "${HOME}/dotfiles/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
    # keep vi-command-mode k/j for plain history navigation instead of autocomplete's menu jump
    bindkey -M vicmd 'k' up-line-or-history
    bindkey -M vicmd 'j' down-line-or-history
    # cycle completions on the command line with Tab / Shift-Tab instead of arrow keys
    bindkey '^I' menu-complete
    bindkey "$terminfo[kcbt]" reverse-menu-complete
fi

# zsh-syntax-highlighting must be end of .zshrc
if [[ -e "${HOME}/dotfiles/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
    source "${HOME}/dotfiles/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    # マッチしない括弧
    ZSH_HIGHLIGHT_STYLES[bracket-error]='fg=red,bold'
    # 括弧の階層
    ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg=blue,bold'
    ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg=green,bold'
    ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg=magenta,bold'
    ZSH_HIGHLIGHT_STYLES[bracket-level-4]='fg=yellow,bold'
    ZSH_HIGHLIGHT_STYLES[bracket-level-5]='fg=cyan,bold'
    # カーソルがある場所の括弧にマッチする括弧
    ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]='standout'
fi
export PATH="/opt/homebrew/opt/curl/bin:$PATH"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
source_if_exists ~/.p10k.zsh
