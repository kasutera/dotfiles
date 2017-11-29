set nocompatible "vi互換なし
set autoindent
set breakindent "インデント付き折り返し
set smarttab
set showmatch "対応括弧のハイライト
set relativenumber
set number
set tabstop=4        " タブを表示するときの幅
set shiftwidth=4    " タブを挿入するときの幅
set expandtab
set showtabline=2	" タブを常に表示 
set visualbell t_vb= " ビープ音なし 
set nobackup
set cursorline "カーソル行のハイライト
set whichwrap=b,s,h,l,<,>,[,]
set wildmode=list,full "補完設定
set clipboard=unnamed,autoselect "クリップボード共有
set incsearch "インクリメンタル検索
set hlsearch "検索結果のハイライト
set directory=~/.vim_tmp
set backupdir=~/.vim_tmp
set undodir=~/.vim_tmp
set showcmd
set smartcase "delete keyを機能
set backspace=indent,eol,start
set shellcmdflag=-ic "シェルの外部コマンドがinteractive に

set list
set listchars=tab:>.

syntax enable
set background=dark
colorscheme solarized

" 引用符, 括弧の設定
"inoremap { {}<Left>
"inoremap [ []<Left>
"inoremap ( ()<Left>
"inoremap ' ''<Left>
"inoremap < <><Left> 

" コマンドモード， <C-m> で make
noremap <C-m> :! mmake 

imap <c-j> <esc>

" アルファベットのインクリメント
set nf=alpha

" カレント行ハイライト
set cursorline
" アンダーラインを引く(color terminal)
highlight CursorLine cterm=underline ctermfg=NONE ctermbg=NONE
" アンダーラインを引く(gui)
highlight CursorLine gui=underline guifg=NONE guibg=NONE


"---------------------------
" Start Neobundle Settings.
"---------------------------
" bundleで管理するディレクトリを指定
set runtimepath+=~/.vim/bundle/neobundle.vim/
call neobundle#begin(expand('~/.vim/bundle/'))

" neobundle自体をneobundleで管理
NeoBundleFetch 'Shougo/neobundle.vim'

NeoBundle 'plasticboy/vim-markdown'
NeoBundle 'tyru/open-browser.vim'

" html
NeoBundle 'mattn/emmet-vim'
NeoBundle 'tpope/vim-surround'
" end html

NeoBundle 'kannokanno/previm'
augroup PrevimSettings
    autocmd!
    autocmd BufNewFile,BufRead *.{md,mdwn,mkd,mkdn,mark*} set filetype=markdown
    let g:previm_open_cmd = 'open -a Safari'
augroup END

call neobundle#end()

" Required:
filetype plugin indent on

" 未インストールのプラグインがある場合、インストールするかどうかを尋ねてくれるようにする設定
" 毎回聞かれると邪魔な場合もあるので、この設定は任意です。
NeoBundleCheck

"-------------------------
" End Neobundle Settings.
"-------------------------

augroup fileTypeIndent
    autocmd!
    autocmd BufNewFile,BufRead *.asm setlocal noexpandtab tabstop=8 softtabstop=8 shiftwidth=8
    autocmd BufNewFile,BufRead *.html setlocal expandtab tabstop=1 softtabstop=1 shiftwidth=1
    autocmd BufNewFile,BufRead *.tex setlocal tabstop=2 softtabstop=2 shiftwidth=2
augroup END

" filetype プラグインによる indent を on にする
filetype plugin indent on

"-------------------------
" Make Settings
"-------------------------

"autocmd FileType scala :command Make call s:Make()

autocmd QuickfixCmdPost make,grep,grepadd,vimgrep copen

