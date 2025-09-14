return {
  {
    'stevearc/conform.nvim',
    init = function()
      -- <leader>f で formatter を実行する
      vim.keymap.set('n', '<leader>f', require 'conform'.format, { silent = true, desc = 'format' })
    end,
    opts = function()
      local js_formatters = { "biome", "prettierd", "prettier", stop_after_first = true }

      return {
        args = {
          "--indent-width=2",
          "--indent-sylte=space",
        },
        formatters_by_ft = {
          html = { 'injected', lsp_format = 'first' },
          lua = { 'stylua', stop_after_first = true },
          javascript = js_formatters,
          typescript = js_formatters,
          typescriptreact = js_formatters,
        },
        format_on_save = {
          timeout_ms = 2000,
          lsp_fallback = true,
          quiet = false,
        },
        default_format_opts = {
          lsp_format = 'last',
        },
      }
    end
  }
}
