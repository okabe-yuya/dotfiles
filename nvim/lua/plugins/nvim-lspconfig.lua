return {
  "neovim/nvim-lspconfig",
  dependencies = { 'saghen/blink.cmp' },
  lazy = true,
  config = function()
    -- 静的に設定を読み込むLSPサーバーの設定
    -- masonを使っても良いが、neovimで書く言語が限られているので、手動で設定している
    local servers = { "lua_ls", "ts_ls" }

    local lspconfig = require("lspconfig")
    for _, server in ipairs(servers) do
      lspconfig[server].setup({})
    end

    vim.lsp.enable(servers)

    -- Error表示
    vim.o.updatetime = 300 -- カーソルが止まった後にエラー表示されるまでの時間(ms)
    vim.cmd([[
      autocmd CursorHold * lua vim.diagnostic.open_float(nil, { focusable = false })
    ]])
  end,
  event = { "BufReadPre", "BufNewFile" }, -- ファイルを開いたときに読み込む
}
