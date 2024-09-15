# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
source_if_exists() {
    if [[ -r "$1" ]]; then
        source "$1"
    fi
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
  for c in {a,i}{\',\",\`}; do
    bindkey -M $m $c select-quoted
  done
done

# braking line by ^J on command line
bindkey '^J' self-insert

# esc lag
KEYTIMEOUT=1

# 文字コード
export LANG=ja_JP.UTF-8

# clang
# export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:"/opt/local/include/"
# export LIBRARY_PATH=$LIBRARY_PATH:"/opt/local/lib/"

# ベルを鳴らさない。
setopt no_beep

# less display prompt (-M), ANSI escape sequence (-R), not to pagenate if less than a page (-F), keep output (-X)
export LESS='-M -R -F -X'

#export PATH=/opt/local/bin:$PATH

# bat theme
export BAT_THEME='Solarized (dark)'
type batcat >> /dev/null && alias bat=batcat


function pbf () {
    echo ${@:1:($#)}
}

function md2pdf(){
  pandoc $1.md -o $2.pdf -V documentclass=ltjsarticle --pdf-engine=lualatex
}

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
autoload -U compinit ; compinit          # オプションを補完
bindkey "^[[Z" reverse-menu-complete     # Shift-Tabで補完候補を逆順する
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
setopt nonomatch                         # *による補完
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS} # ファイル補完候補に色を付ける


# ############################################################# #
# prompt                                                        #
# ############################################################# #
SPROMPT="%R -> %r ? [Yes/No/Abort/Edit]"

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

# Use beam shape cursor for each new prompt.
preexec_cursor() {
   echo -ne '\e[6 q'
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec preexec_cursor

zle -N zle-line-init
zle -N zle-keymap-select

autoload -Uz vcs_info
setopt prompt_subst
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{yellow}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{red}+"
zstyle ':vcs_info:*' formats "%F{green}%c%u[%b]%f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'
precmd () {
    vcs_info
    echo -ne "\e]1;$(basename $PWD)\a"
}

# ############################################################# #
# alias                                                         #
# ############################################################# #
alias c='clear'
alias cp='cp -i'
alias mv='mv -i'
alias ls='ls -aGF'
alias cppwd='pwd | pbcopy'
alias cdcp='cd $(pbpaste)'
alias ql='qlmanage -p "$@" >& /dev/null'
alias history-all='history -E 1'
alias hist-grep='history-all | grep'
alias emacs='vim'
alias v='vim'
alias vi='vim'
type nvim >> /dev/null && alias vim='nvim'
alias clang++='clang++ -Wall -Wc++11-extensions'
alias gcc='clang'
alias g++='clang++'
type gdate >> /dev/null && alias date='gdate'
alias pbtee='tee >(pbcopy)'
alias tig='tig --all'
alias :q='exit'

transfer() {
    # check arguments
    if [ $# -eq 0 ]; then
        echo "No arguments specified. Usage:\necho transfer /tmp/test.md\ncat /tmp/test.md | transfer test.md"
        return 1
    fi

    # get temporarily filename, output is written to this file show progress can be showed
    tmpfile=$( mktemp -t transferXXX )

    # upload stdin or file
    file=$1

    if tty -s; then
        basefile=$(basename "$file" | sed -e 's/[^a-zA-Z0-9._-]/-/g')

        if [ ! -e $file ]; then
            echo "File $file doesn't exists."
            return 1
        fi

        if [ -d $file ]; then
            # zip directory and transfer
            zipfile=$( mktemp -t transferXXX.zip )
            cd $(dirname $file) && zip -r -q - $(basename $file) >> $zipfile
            curl --progress-bar --upload-file "$zipfile" "https://transfer.sh/$basefile.zip" >> $tmpfile
            rm -f $zipfile
        else
            # transfer file
            curl --progress-bar --upload-file "$file" "https://transfer.sh/$basefile" >> $tmpfile
        fi
    else
        # transfer pipe
        curl --progress-bar --upload-file "-" "https://transfer.sh/$file" >> $tmpfile
    fi

    # cat output link
    cat $tmpfile

    # cleanup
    rm -f $tmpfile
}

# with suffix
function runc () { g++ $1 && shift && ./a.out $@ }
function runcpp () { g++ $1 && shift && ./a.out $@ }
function runawk () { awk -f $@ }

function mmake () {
    if [ -e "Makefile" ]; then
        make $@
    elif [ -e "OMakefile" ]; then
        omake $@
    fi
}

alias -s c=runc
alias -s cpp=runcpp
alias -s {png,jpg,bmp,tif,tiff,PNG,JPG,BMP,TIF,TIFF}=open
alias -s awk=runawk

# ############################################################# #
# zmv                                                           #
# ############################################################# #
autoload zmv
alias zmv='noglob zmv -W'

reverse() {
    awk '{a[i++]=$0} END {for (j=i-1; j>=0;) print a[j--] }'
}

# peco (コマンド検索)
function peco-history-selection() {
    BUFFER=$(history -n 1 | reverse | awk '!a[$0]++' | peco)
    CURSOR=$#BUFFER
    zle reset-prompt
}

zle -N peco-history-selection
bindkey '^R' peco-history-selection

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

function do_enter() {
    if [ -n "$BUFFER" ]; then
        zle accept-line
        return 0
    fi
    echo
    ls
    # ↓おすすめ
    # ls_abbrev
    if [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" = 'true' ]; then
        echo
        echo -e "\e[0;33m--- git status ---\e[0m"
        git status -sb
    fi
    zle reset-prompt
    return 0
}
zle -N do_enter
bindkey '^m' do_enter

# 名前で色を付けるようにする
autoload colors
colors

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
