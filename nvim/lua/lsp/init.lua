-- config はnvim-lspconfig から読み込み済み
-- plugins が読み込み完了してから、実行しないと設定が反映されない

local lsp_servers = {
  "lua_ls",
  "ts_ls",
  "ruby_lsp",
  "jsonls",
  "kotlin_lsp",
}

vim.lsp.enable(lsp_servers)
