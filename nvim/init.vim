" ------------------------------------
"  . *. . Neovim config  . *. .
" ------------------------------------

" ftpluginの有効化
filetype plugin on

set shell=/bin/zsh " コマンドの実行にはzshを使用する
set shiftwidth=2 " indentの幅
set tabstop=2 " タブに変換されるサイズ
set expandtab " タブ入力の際にスペース
set textwidth=0 " ワードラッピングなし
set autoindent " 自動インデント
set hlsearch " Searchのハイライト
set clipboard=unnamed " クリップボードへの登録
syntax on " syntaxを有効

" ファイルをデフォルトで右側に表示する
set splitright

" 背景透過
set pumblend=10
set winblend=10

set number " 行番号を表示

" Shift+pで改行して貼り付けを行う
nnoremap P o<Esc>p

" iterm2 + nvimで文字がちらつく事象の対応
set ambiwidth=single

" 文字を折り返さない
set nowrap

" vim plug
call plug#begin()
    " A File Explorer For Neovim
    Plug 'nvim-tree/nvim-tree.lua'

    " nerdtree: file window manager
    " Plug 'preservim/nerdtree'
    
    " telescope: fzf finder tool
    Plug 'nvim-lua/plenary.nvim'
    Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.8' }
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'
 
    " schema(vim color theme)
    Plug 'rebelot/kanagawa.nvim'

    " Comment: easy comentout tool
    Plug 'numToStr/Comment.nvim'

    " LSP
    Plug 'Shougo/ddc.vim'
    Plug 'vim-denops/denops.vim'
    Plug 'Shougo/ddc-around'
    Plug 'Shougo/ddc-matcher_head'
    Plug 'Shougo/ddc-ui-native'

    " im-select manager
    Plug 'keaising/im-select.nvim'

    " LSP pack
    Plug 'sheerun/vim-polyglot' 

    " Plug 'williamboman/mason.nvim'
    " Plug 'williamboman/mason-lspconfig.nvim'
    Plug 'neovim/nvim-lspconfig'

    Plug 'hrsh7th/nvim-cmp'
    Plug 'hrsh7th/cmp-nvim-lsp'
    Plug 'hrsh7th/vim-vsnip'
call plug#end()

" schema settings
source ~/dotfiles/nvim/color-scheme.vim

" 背景の透過設定
" ターミナルの透過設定をnvimにも反映させる
set laststatus=3
" 基本UI
highlight Normal guibg=NONE ctermbg=NONE
highlight NormalNC guibg=NONE ctermbg=NONE
highlight EndOfBuffer guibg=NONE ctermbg=NONE

" 行番号・記号
highlight LineNr guibg=NONE ctermbg=NONE
highlight CursorLineNr guibg=NONE ctermbg=NONE
highlight SignColumn guibg=NONE ctermbg=NONE
highlight FoldColumn guibg=NONE ctermbg=NONE

" ステータスライン周辺
highlight VertSplit guibg=NONE ctermbg=NONE
highlight WinSeparator guibg=NONE ctermbg=NONE
highlight StatusLine guibg=NONE ctermbg=NONE blend=100
highlight StatusLineNC guibg=NONE ctermbg=NONE blend=100

" コマンドライン／メッセージ領域
highlight MsgArea guibg=NONE ctermbg=NONE
highlight MsgSeparator guibg=NONE ctermbg=NONE
highlight CommandLine guibg=NONE ctermbg=NONE
highlight ModeMsg guibg=NONE ctermbg=NONE
highlight MoreMsg guibg=NONE ctermbg=NONE
highlight ErrorMsg guibg=NONE ctermbg=NONE
highlight WarningMsg guibg=NONE ctermbg=NONE
highlight WildMenu guibg=NONE ctermbg=NONE

" プラグイン設定の読み込み
for fpath in globpath('~/dotfiles/nvim/plugins', '*.vim', 0, 1)
    execute 'source' fpath
endfor

