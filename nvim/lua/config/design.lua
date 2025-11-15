-- ウィンドウ境界線を非表示
vim.api.nvim_set_hl(0, "WinSeparator", { bg = "none" })
vim.opt.fillchars:append {
  vert = ' ',
  horiz = ' ',
}

-- ステータスバーを非表示
vim.opt.laststatus = 0

