local M = {}

function M.config()
  -- neovim/lspconfigを使わなくても良いが、設定の記述が単調なので利用する
  local lspconfig = require("lspconfig")

  -- 静的に設定を読み込むLSPサーバーの設定
  -- masonを使っても良いが、neovimで書く言語が限られているので、手動で設定している
  lspconfig.lua_ls.setup({})
  lspconfig.ts_ls.setup({})
end

-- LSPを有効化する
vim.lsp.enable({
  "lua_ls",
  "ts_ls",
})

return M
