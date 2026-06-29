-- config はnvim-lspconfig から読み込み済み
-- plugins が読み込み完了してから、実行しないと設定が反映されない

-- nvim-lspconfig のデフォルトに含まれる 'javascript.jsx' / 'typescript.tsx' は
-- Neovim 0.11+ では未知 filetype として警告が出るため、現代の filetype 名のみに上書き
vim.lsp.config('ts_ls', {
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
})

local lsp_servers = {
  "lua_ls",
  "ts_ls",
  "ruby_lsp",
  "jsonls",
  "kotlin_lsp",
}

vim.lsp.enable(lsp_servers)
