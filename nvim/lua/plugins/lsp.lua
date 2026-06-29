return {
  -- lsp のconfig 設定集
  -- 記述する言語が限られているため、lsp のインストール補助ツールの Mason は使わない（依存は最小限に止める）
  -- 補完 / hover / rename / code action / references は Neovim 0.11+ の組み込みデフォルトを利用
  -- (K, grn, gra, grr などはマッピング不要)
  {
    "neovim/nvim-lspconfig",
    dependencies = { 'saghen/blink.cmp' },
    lazy = true,

    -- バッファの読み込みをトリガーに起動
    event = {
      "BufReadPre",
      "BufNewFile",
    },
    init = function()
      -- エラー箇所は波線でハイライトし、詳細はフロートで表示する
      vim.diagnostic.config({
        virtual_text = false,
        underline = true,
        signs = true,
        float = { border = "rounded", focusable = false, source = true },
      })

      -- カーソルが diagnostic 上に乗って updatetime 経過後にフロートを自動表示
      vim.api.nvim_create_autocmd("CursorHold", {
        group = vim.api.nvim_create_augroup("MyDiagnosticHover", { clear = true }),
        pattern = "*",
        callback = function()
          vim.diagnostic.open_float(nil, { focus = false, scope = "cursor" })
        end,
      })

      local group = vim.api.nvim_create_augroup('MyLspMaps', { clear = true })
      vim.api.nvim_create_autocmd('LspAttach', {
        group = group,
        callback = function(ev)
          local map = vim.keymap.set
          local opt = function(desc)
            return { silent = true, buffer = ev.buf, desc = desc }
          end

          -- 行のエラー詳細をフロート表示 (組み込み <C-w>d でも可)
          map('n', 'ge', vim.diagnostic.open_float, opt('show line diagnostics'))

          -- diagnostic ジャンプ (組み込み ]d / [d でも可)
          map('n', '<leader>j', function() vim.diagnostic.jump({ count = 1, float = true }) end, opt('next diagnostic'))
          map('n', '<leader>k', function() vim.diagnostic.jump({ count = -1, float = true }) end, opt('prev diagnostic'))
        end,
      })
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
