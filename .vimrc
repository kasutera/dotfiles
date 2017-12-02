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

augroup fileTypeIndent
    autocmd!
    autocmd BufNewFile,BufRead *.asm setlocal noexpandtab tabstop=8 softtabstop=8 shiftwidth=8
    autocmd BufNewFile,BufRead *.html setlocal expandtab tabstop=1 softtabstop=1 shiftwidth=1
    autocmd BufNewFile,BufRead *.tex setlocal tabstop=2 softtabstop=2 shiftwidth=2
augroup END

" filetype プラグインによる indent を on にする
filetype plugin indent on

" ---------------------------------------------------------------------------------
"  dein
" ---------------------------------------------------------------------------------
set runtimepath+=~/.vim/dein/repos/github.com/Shougo/dein.vim

if dein#load_state('~/.vim/dein')
  call dein#begin('~/.vim/dein')

  " Let dein manage dein
  " Required:
  call dein#add('~/.vim/dein/repos/github.com/Shougo/dein.vim')

  " Add or remove your plugins here:

  " You can specify revision/branch/tag.

  " Required:
  call dein#end()
  call dein#save_state()
endif

" Required:
filetype plugin indent on
syntax enable

" If you want to install not installed plugins on startup.
if dein#check_install()
  call dein#install()
endif

" ---------------------------------------------------------------------------------
"  end dein scripts
" ---------------------------------------------------------------------------------
