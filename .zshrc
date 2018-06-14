# ############################################################# #
# history                                                       #
# ############################################################# #
export HISTFILE="$HOME/.zsh_history"     # 履歴をファイルに保存する
export HISTSIZE=100000                   # メモリ内の履歴の数
export SAVEHIST=100000                   # 保存される履歴の数
setopt extended_history                  # 履歴ファイルに時刻を記録
setopt hist_ignore_dups                  # 重複を記録しない
# setopt inc_append_history              # 端末間でヒストリを共有
# setopt share_history

export PATH=$PATH:~/bin

# vim keybind
bindkey -v
# esc lag
KEYTIMEOUT=1

# 文字コード
export LANG=ja_JP.UTF-8

# clang
# export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:"/opt/local/include/"
# export LIBRARY_PATH=$LIBRARY_PATH:"/opt/local/lib/"

# ベルを鳴らさない。
setopt no_beep

#export PATH=/opt/local/bin:$PATH

function pbf () {
    echo ${@:1:($#)}
}

function md2pdf(){
  pandoc $1.md -o $2.pdf -V documentclass=ltjsarticle --latex-engine=lualatex
}

csvless(){
    if [[ $# -eq 0 ]]; then
        column -s, -t | less -#2 -N -S
    else
        column -s, -t < $1 | less -#2 -N -S
    fi
}

# ############################################################# #
# completion                                                    #
# ############################################################# #

setopt autocd                            # cdつけなくてもcd
setopt auto_pushd                        # 過去のディレクトリ
setopt correct                           # 訂正
fpath=(/usr/local/share/zsh-completions $fpath)
autoload -U compinit ; compinit          # オプションを補完 
bindkey "^[[Z" reverse-menu-complete     # Shift-Tabで補完候補を逆順する
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
setopt nonomatch                         # *による補完
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS} # ファイル補完候補に色を付ける


# ############################################################# #
# prompt                                                        #
# ############################################################# #
PROMPT="%F{green}[%n@%m %~]%f "'${vcs_info_msg_0_}'"
%F{blue}[%D{%m/%d %T}]%f$ "
SPROMPT="%R -> %r ? [Yes/No/Abort/Edit]"

function zle-line-init zle-keymap-select {
    RPS1="${${KEYMAP/vicmd/-- NORMAL -- }/(main|viins)/-- INSERT -- }"
    RPS2=$RPS1
    zle reset-prompt
}

zle -N zle-line-init
zle -N zle-keymap-select

autoload -Uz vcs_info
setopt prompt_subst
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{yellow}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{red}+"
zstyle ':vcs_info:*' formats "%F{green}%c%u[%b]%f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'
precmd () { vcs_info }

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
    if [ $# -eq 0 ]; 
    then 
        echo "No arguments specified. Usage:\necho transfer /tmp/test.md\ncat /tmp/test.md | transfer test.md"
        return 1
    fi

    # get temporarily filename, output is written to this file show progress can be showed
    tmpfile=$( mktemp -t transferXXX )
    
    # upload stdin or file
    file=$1

    if tty -s; 
    then 
        basefile=$(basename "$file" | sed -e 's/[^a-zA-Z0-9._-]/-/g') 

        if [ ! -e $file ];
        then
            echo "File $file doesn't exists."
            return 1
        fi
        
        if [ -d $file ];
        then
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

# peco (コマンド検索)
function peco-history-selection() {
    BUFFER=`history -n 1 | tail -r  | awk '!a[$0]++' | peco`
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

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# 追加ファイルがあるならインポート
test -e "${HOME}/.zsh_extrc" && source "${HOME}/.zsh_extrc"
