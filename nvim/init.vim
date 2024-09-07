" neovim config " 

set shell=/bin/zsh " コマンドの実行にはzshを使用する
set shiftwidth=4 " indentの幅
set tabstop=4 " タブに変換されるサイズ
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

" vim plug
call plug#begin()
    Plug 'preservim/nerdtree'

    Plug 'nvim-lua/plenary.nvim'
    Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.8' }

    " カラースキーマ
    Plug 'cocopon/iceberg.vim'

    " status line customizer
    Plug 'nvim-lualine/lualine.nvim'
    " If you want to have icons in your statusline choose one of these
    Plug 'nvim-tree/nvim-web-devicons'
     
    Plug 'numToStr/Comment.nvim'

    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'
    
    " LSP
    Plug 'Shougo/ddc.vim'
    Plug 'vim-denops/denops.vim'
    Plug 'Shougo/ddc-around'
	Plug 'Shougo/ddc-matcher_head'
    Plug 'Shougo/ddc-ui-native'

    " im-select manager
    Plug 'keaising/im-select.nvim'

    " rich status line
    Plug 'nvim-lualine/lualine.nvim'
    Plug 'nvim-tree/nvim-web-devicons'

    " LSP pack
    Plug 'sheerun/vim-polyglot' 
    Plug 'williamboman/mason.nvim'
    Plug 'williamboman/mason-lspconfig.nvim'
    Plug 'neovim/nvim-lspconfig'
call plug#end()

" schema settings
source ~/dotfiles/nvim/color-scheme.vim

" load plugins
for fpath in globpath('~/dotfiles/nvim/plugins', '*.vim', 0, 1)
    execute 'source' fpath
endfor

