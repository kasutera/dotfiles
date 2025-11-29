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

# braking line by ^J on command line
bindkey '^J' self-insert

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

function mmake () {
    if [ -e "Makefile" ]; then
        make $@
    elif [ -e "OMakefile" ]; then
        omake $@
    fi
}

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
    BUFFER=$(history -n 1 | awk '!a[$0]++' | reverse | FILTER | sed 's/\\n/\n/g')
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

source_if_exists "${HOME}/.iterm2_shell_integration.zsh"

# cd-gitroot
if [[ -e "${HOME}"/dotfiles/cd-gitroot ]]; then
    fpath=("${HOME}"/dotfiles/cd-gitroot $fpath)
    autoload -Uz cd-gitroot
fi

# 追加ファイルがあるならインポート
source_if_exists "${HOME}/.zsh_extrc"

source_if_exists "${HOME}/dotfiles/powerlevel10k/powerlevel10k.zsh-theme"

if [[ -e ~/dotfiles/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source "${HOME}/dotfiles/zsh-autosuggestions/zsh-autosuggestions.zsh"
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#626262"
    # use ctrl-p instead of right-arrow
    bindkey '^p' autosuggest-accept
fi

# zsh-autocomplete
if [[ -e "${HOME}/dotfiles/zsh-autocomplete/zsh-autocomplete.plugin.zsh" ]]; then
    source "${HOME}/dotfiles/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
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
