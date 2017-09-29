if has('gui_macvim')
    " 透明度を指定
	set transparency=10
    " アンチエイリアス
	set antialias
    " ツールバー非表示
	set guioptions-=t
    " 右スクロールバー非表示
	set guioptions-=r
	set guioptions-=R
    " 左スクロールバー非表示
	set guioptions-=l
	set guioptions-=L
	set guifont=Osaka-Mono:h14

	" insert modeから抜ける時日本語入力を切る
	set noimdisableactivate

	" 縦幅　デフォルトは24
    set lines=80
    " 横幅　デフォルトは80
    set columns=100

	"カラースキームの設定
    syntax enable
    set background=dark
    colorscheme solarized
endif
