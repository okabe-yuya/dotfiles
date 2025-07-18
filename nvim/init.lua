-- ------------------------------------
--  . *. . Plugin settings  . *. .
-- ------------------------------------
-- 読み込みパスの拡張
-- package.path = package.path .. ";" .. vim.fn.expand("~/dotfiles/nvim/lua/?.lua")

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
-- color schema設定の読み込み
vim.opt.termguicolors = true

vim.cmd([[colorscheme kanagawa]])

-- ビジュアルモードの選択時の色の設定
-- 背景透過をしていると、選択している箇所の判別がつかないため設定
vim.cmd([[highlight Visual ctermbg=darkgrey guibg=#5f5f5f]])

-- lightline
vim.g.lightline = {}
vim.g.lightline.colorscheme = 'kanagawa'

-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

---- 背景の透過設定
-- ターミナルの透過設定をnvimにも反映させる
local highlights = {
  "Normal", "NormalNC", "EndOfBuffer",

  -- 行番号・記号
  "LineNr", "CursorLineNr", "SignColumn", "FoldColumn",

  -- ステータスライン周辺
  "VertSplit", "WinSeparator", "StatusLine", "StatusLineNC",

  -- コマンドライン／メッセージ領域
  "MsgArea", "MsgSeparator", "CommandLine", "ModeMsg",
  "MoreMsg", "ErrorMsg", "WarningMsg", "WildMenu"
}

for _, group in ipairs(highlights) do
  vim.cmd("highlight " .. group .. " guibg=NONE ctermbg=NONE")
end

-- ステータスラインのblend
vim.cmd("highlight StatusLine blend=100")
vim.cmd("highlight StatusLineNC blend=100")
