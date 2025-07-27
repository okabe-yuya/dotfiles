-- ------------------------------------
--  . *. . Plugin settings  . *. .
-- ------------------------------------
-- プラグイン設定の読み込み
require("config.lazy") -- lazy.nvimの設定


-- ------------------------------------
--  . *. . Command config  . *. .
-- ------------------------------------
-- ftpluginの有効化
vim.cmd("filetype plugin on")

-- syntaxを有効
vim.cmd("syntax on")

-- ------------------------------------
--  . *. . Key settings  . *. .
-- ------------------------------------
-- Shift+pで改行して貼り付けを行う
vim.api.nvim_set_keymap('n', 'P', 'o<Esc>p', { noremap = true, silent = true })

-- 画面分割
vim.api.nvim_set_keymap('n', 'sv', ':vsplit<Return><C-w>w', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'ss', ':split<Return><C-w>w', { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', 'sh', '<C-w>h', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'sk', '<C-w>k', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'sj', '<C-w>j', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'sl', '<C-w>l', { noremap = true, silent = true })

-- ------------------------------------
--  . *. . Option settings  . *. .
-- ------------------------------------
-- コマンドの実行にはzshを使用する
vim.opt.shell = "/bin/zsh"

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

-- 背景透過
vim.opt.pumblend = 10
vim.opt.winblend = 10

-- 行番号を表示
vim.opt.number = true

-- iterm2 + nvimで文字がちらつく事象の対応
vim.opt.ambiwidth = "single"

-- 文字を折り返さない
vim.opt.wrap = false

-- 常にステータスラインを1つだけ表示する
vim.opt.laststatus = 3


-- ------------------------------------
--  . *. . UI settings  . *. .
-- ------------------------------------
vim.opt.termguicolors = true
vim.opt.winblend = 0 -- ウィンドウの不透明度
vim.opt.pumblend = 0 -- ポップアップメニューの不透明度

vim.cmd [[
  colorscheme kanagawa

  " ビジュアルモードの選択時の色の設定
  " 背景透過をしていると、選択している箇所の判別がつかないため設定
  highlight Visual ctermbg=darkgrey guibg=#5f5f5f

  highlight StatusLine guibg=default guifg=default " status line
  highlight LineNr guibg=default guifg=default " 行番号
  highlight SignColumn guibg=default

  " LSP診断サインの背景色も透明に（default背景利用）
  highlight DiagnosticSignWarn  guibg=none
  highlight DiagnosticSignError guibg=none
  highlight DiagnosticSignInfo  guibg=none
  highlight DiagnosticSignHint  guibg=none

  " GitSignsプラグイン用のサイン背景もnoneに
  highlight GitSignsAdd    guibg=none
  highlight GitSignsChange guibg=none
  highlight GitSignsDelete guibg=none

  " Telescope
  highlight TelescopeBorder guibg=NONE guifg=NONE
  highlight TelescopePromptBorder guibg=NONE guifg=NONE
  highlight TelescopeResultsBorder guibg=NONE guifg=NONE
  highlight TelescopePreviewBorder guibg=NONE guifg=NONE

  " Tabline
  highlight BufferTabpageFill guibg=default
  highlight TabLineFill guibg=NONE ctermbg=NONE
]]

-- disable netrw(default file browser) at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
