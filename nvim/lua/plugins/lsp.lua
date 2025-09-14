return {
  -- lsp のconfig 設定集
  -- 記述する言語が限られているため、lsp のインストール補助ツールの Mason は使わない（依存は最小限に止める）
  {
    "neovim/nvim-lspconfig",
    dependencies = { 'saghen/blink.cmp' },
    lazy = true,

    -- バッファの読み込みをトリガーに起動
    event = {
      "BufReadPre",
      "BufNewFile",
    }
  },

  -- lsp 情報の表示をリッチに
  {
    'glepnir/lspsaga.nvim',
    event = 'BufRead',
    opts = {
      finder = {
        keys = {
          toggle_or_open = '<CR>',
          quit = { 'q', '<ESC>' },
        },
      },
      symbol_in_winbar = {
        enable = false
      },
    },
    init = function()
      local group = vim.api.nvim_create_augroup('MyLspSagaMaps', { clear = true })

      vim.api.nvim_create_autocmd('LspAttach', {
        group = group,
        callback = function(ev)
          local map = vim.keymap.set
          local opt = function(desc)
            return { silent = true, buffer = ev.buf, desc = desc }
          end

          map('n', 'gd', '<cmd>Lspsaga goto_definition<CR>', opt())
          map('n', 'gp', '<cmd>Lspsaga peek_definition<CR>', opt())
          map('n', 'grr', '<cmd>Lspsaga finder<CR>', opt())
          map('n', 'K', '<cmd>Lspsaga hover_doc<CR>', opt())
          map('n', 'grn', '<cmd>Lspsaga rename<CR>', opt('rename using LSP'))

          map('n', 'gra', '<cmd>Lspsaga code_action<CR>', opt('open code action'))

          map('n', 'ge', '<cmd>Lspsaga show_line_diagnostics<CR>', opt('show line diagnostics'))
          map('n', '<leader>j', '<cmd>Lspsaga diagnostic_jump_next<CR>', opt())
          map('n', '<leader>k', '<cmd>Lspsaga diagnostic_jump_prev<CR>', opt())

          map('n', '<leader>o', '<cmd>Lspsaga outline<CR>', opt('show outline'))
        end,
      })
    end,
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
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
