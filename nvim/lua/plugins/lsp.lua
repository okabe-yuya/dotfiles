return {
  -- LSP の設定
  -- 記述する言語が限られているため、lsp のインストール補助ツールの Mason は使わない（依存は最小限に止める）
  -- 補完 / hover / rename / code action / references は Neovim 0.11+ の組み込みデフォルトを利用
  -- (K, grn, gra, grr などはマッピング不要)
  --
  -- nvim-lspconfig は lsp/*.lua の設定ソースを提供するだけのため eager に読み込む
  -- (vim.lsp.enable を遅延させる必要がなく、blink.cmp 依存も同時に解決できる)
  {
    "neovim/nvim-lspconfig",
    dependencies = { 'saghen/blink.cmp' },
    config = function()
      -- エラー箇所は波線でハイライトし、詳細はフロートで表示する
      vim.diagnostic.config({
        virtual_text = false,
        underline = true,
        signs = true,
        float = { border = "rounded", focusable = false, source = true },
      })

      -- カーソルが diagnostic 上に乗って updatetime 経過後にフロートを自動表示
      -- ファイルバッファ以外 (terminal, oil, help 等) では発火させない
      vim.api.nvim_create_autocmd("CursorHold", {
        group = vim.api.nvim_create_augroup("MyDiagnosticHover", { clear = true }),
        pattern = "*",
        callback = function(args)
          if vim.bo[args.buf].buftype ~= "" then return end
          vim.diagnostic.open_float(nil, { focus = false, scope = "cursor" })
        end,
      })

      -- 全 LSP server に blink.cmp の補完 capabilities を伝える
      vim.lsp.config('*', {
        capabilities = require('blink.cmp').get_lsp_capabilities(),
      })

      -- nvim-lspconfig のデフォルト ts_ls には 'javascript.jsx' / 'typescript.tsx' という
      -- レガシー filetype が含まれ Neovim 0.11+ で警告が出るため、現代の名前のみに絞る
      vim.lsp.config('ts_ls', {
        filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
      })

      -- LSP server の有効化
      vim.lsp.enable({
        "lua_ls",
        "ts_ls",
        "ruby_lsp",
        "jsonls",
        "kotlin_lsp",
      })

      -- diagnostic 操作のキーマップ (vim.diagnostic は LSP attach 非依存なのでグローバルに登録)
      -- カーソル静止で自動フロート表示するため、手動表示用のマッピングは不要
      local map = vim.keymap.set
      map('n', '<leader>j', function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = 'next diagnostic' })
      map('n', '<leader>k', function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = 'prev diagnostic' })
    end,
  },

  -- スニペットの導入
  {
    "L3MON4D3/LuaSnip",
    dependencies = { "rafamadriz/friendly-snippets" },
    version = "v2.*",
    build = "make install_jsregexp",
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()

      -- Load custom snippets
      require("luasnip.loaders.from_lua").load()
    end,
  }
}
