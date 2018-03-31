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
set noswapfile
set writebackup
set backupcopy=no
set cursorline "カーソル行のハイライト
set whichwrap=b,s,h,l,<,>,[,]
set wildmode=list,full "補完設定
if has("nvim")
    set clipboard+=unnamedplus
else
    set clipboard=unnamed,autoselect "クリップボード共有
endif
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

" symbolic link edit
command! FollowSymlink call s:SwitchToActualFile()
function! s:SwitchToActualFile()
    let l:fname = resolve(expand('%:p'))
    let l:pos = getpos('.')
    let l:bufname = bufname('%')
    enew
    exec 'bw '. l:bufname
    exec "e" . fname
    call setpos('.', pos)
endfunction

" ---------------------------------------------------------------------------------
"  dein
" ---------------------------------------------------------------------------------

" dein.vimインストール時に指定したディレクトリをセット
let s:dein_dir = expand('~/.vim/dein')

" dein.vimの実体があるディレクトリをセット
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

" dein.vimが存在していない場合はgithubからclone
if &runtimepath !~# '/dein.vim'
  if !isdirectory(s:dein_repo_dir)
    execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
  endif
  execute 'set runtimepath^=' . fnamemodify(s:dein_repo_dir, ':p')
endif

if dein#load_state('~/.vim/dein')
    call dein#begin('~/.vim/dein')

    " dein.toml, dein_layz.tomlファイルのディレクトリをセット
    let s:toml_dir = expand('~/.config/nvim')

    " 起動時に読み込むプラグイン群
    call dein#load_toml(s:toml_dir . '/dein.toml', {'lazy': 0})

    " 遅延読み込みしたいプラグイン群
    call dein#load_toml(s:toml_dir . '/dein_lazy.toml', {'lazy': 1})

    call dein#end()
    call dein#save_state()
endif

syntax enable
set background=dark
colorscheme solarized

" Required:
filetype plugin indent on

" If you want to install not installed plugins on startup.
if dein#check_install()
    call dein#install()
endif


" ---------------------------------------------------------------------------------
"  end dein scripts
" ---------------------------------------------------------------------------------
