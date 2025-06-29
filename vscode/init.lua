-- インデント関連
vim.opt.shiftwidth = 2      -- 自動インデント幅
vim.opt.tabstop = 2         -- タブ表示幅
vim.opt.expandtab = true    -- タブ入力をスペースに変換
vim.opt.autoindent = true   -- 自動インデント

-- テキスト幅と折り返し
vim.opt.textwidth = 0       -- 自動折り返しなし
vim.opt.wrap = false        -- 画面折り返しなし

-- ハイライトと行番号
vim.opt.hlsearch = true     -- 検索ハイライト
vim.opt.number = true       -- 行番号表示

-- クリップボード連携（macOSの場合は"unnamedplus"が主流）
vim.opt.clipboard = "unnamed"

-- シンタックスハイライト
vim.cmd("syntax on")

-- 分割時に右側に開くようにする
vim.opt.splitright = true

-- ポップアップ・ウィンドウの背景透過設定
vim.opt.pumblend = 10       -- ポップアップメニューの透過
vim.opt.winblend = 10       -- 通常ウィンドウの透過

-- 文字列の一括置換
-- https://zenn.dev/vim_jp/articles/2023-06-30-vim-substitute-tips
vim.cmd([[
  cnoreabbrev <expr> s getcmdtype() .. getcmdline() ==# ':s' ? [getchar(), ''][1] .. "%s///g<Left><Left>" : 's'
]])

-- keymap settings
---- リーダーキーを <Space> に設定
vim.g.mapleader = " "

-- （オプション）ローカルリーダーキーも同じにする場合
vim.g.maplocalleader = " "

-- nnoremap P o<Esc>p の再現（Shift + P で改行して貼り付け）
vim.keymap.set("n", "P", "o<Esc>p", { noremap = true, silent = true })

-- package manager
-- lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)


