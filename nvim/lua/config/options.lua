-- コマンドの実行には zsh を使用
vim.opt.shell = "/bin/zsh"

-- 旧形式の日本語ファイル (euc-jp / cp932) を読めるようにする
vim.opt.fileencodings = 'ucs-boms,utf-8,euc-jp,cp932'

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

-- クリップボードへの登録
vim.opt.clipboard = "unnamed"

-- ファイルをデフォルトで右側に表示する
vim.opt.splitright = true

-- 行番号を表示
vim.opt.number = true
vim.opt.relativenumber = true

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

-- カーソル停止から CursorHold 発火までの待ち時間 (ms)
-- swap 書き込みや CursorHold ベースの autocmd (LSP の diagnostic フロート等) に影響
vim.opt.updatetime = 500

-- ウィンドウ境界線を非表示
vim.api.nvim_set_hl(0, "WinSeparator", { bg = "none" })
vim.opt.fillchars:append {
  vert = ' ',
  horiz = ' ',
}

-- code action sign がチラつくので、常に sign 分を表示しておく
vim.opt.signcolumn = "yes"

-- 自動保存
local function autosave()
  -- 保存してよいバッファだけ対象にする
  if vim.bo.buftype ~= "" then return end
  if not vim.bo.modifiable then return end
  if not vim.bo.modified then return end

  -- 書き込み不可な状況を避ける
  if vim.fn.expand("%") == "" then return end

  vim.cmd("silent write")
end

vim.api.nvim_create_autocmd(
  {
    "InsertLeave", -- insert モードを抜けたとき
    "FocusLost",   -- フォーカスを失ったとき
  },
  {
    pattern = "*",
    callback = autosave,
  }
)

-- 不要なプラグインを無効にする (netrw は lazy.nvim の disabled_plugins 側で無効化済み)
vim.g.loaded_gzip = 1
