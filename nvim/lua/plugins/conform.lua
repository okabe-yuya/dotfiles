return {
  'stevearc/conform.nvim',
  opts = {},
  config = function()
    local js_formatters = { "biome", "prettierd", "prettier" }
    require("conform").setup({
      args = {
        "--indent-width=2",
        "--indent-sylte=space",
      },
      format_on_save = {
        timeout_ms = 2000,
        lsp_fallback = true,
        quiet = false,
      },
      formatters_by_ft = {
        lua = { "stylua" },
        json = {
          formatters = js_formatters,
          stop_after_first = true,
        },
        javascript = {
          formatters = js_formatters,
          stop_after_first = true,
        },
        javascriptreact = {
          formatters = js_formatters,
          stop_after_first = true,
        },
        typescript = {
          formatters = js_formatters,
          stop_after_first = true,
        },
        typescriptreact = {
          formatters = js_formatters,
          stop_after_first = true,
        },
      },
    })
  end
}
