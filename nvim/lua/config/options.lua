-- コマンドの実行には zsh を使用
vim.opt.shell = "/bin/zsh"

-- ftpluginを有効
vim.cmd [[filetype plugin on]]


-- 文字コードの設定
vim.scriptencoding = 'utf-8'
vim.opt.fileencoding = 'utf-8'
vim.opt.fileencodings = 'ucs-boms,utf-8,euc-jp,cp932'
vim.opt.fileformats = 'unix,dos,mac'

-- カーソル行をハイライト
vim.opt.cursorline = true

-- カーソル移動時に上下10行分の余白を確保
vim.opt.scrolloff = 10

-- マウス操作を無効
vim.opt.mouse = ""

-- indentの幅
vim.opt.shiftwidth = 2

-- タブに変換されるサイズ
vim.opt.tabstop = 2

-- タブ入力の際にスペース
vim.opt.expandtab = true

-- ワードラッピングなし
vim.opt.textwidth = 0

-- 自動インデント
vim.opt.autoindent = true

-- Searchのハイライト
vim.opt.hlsearch = true

-- クリップボードへの登録
vim.opt.clipboard = "unnamed"

-- ファイルをデフォルトで右側に表示する
vim.opt.splitright = true

-- 行番号を表示
vim.opt.number = true
vim.opt.relativenumber = true

-- iterm2 + nvimで文字がちらつく事象の対応
vim.opt.ambiwidth = "single"

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

-- 文字を折り返さない
vim.opt.wrap = false

-- エラー時のビープ音をミュート
vim.opt.visualbell = true

-- コメントの連続入力をブロック
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    local opt = vim.opt_local
    opt.formatoptions:remove({ 'c', 'r', 'o' })
  end,
})

-- カーソル行のエラーを表示
vim.diagnostic.config({
  virtual_text = { current_line = true }
})
