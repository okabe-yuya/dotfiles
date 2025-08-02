return {
  "saghen/blink.cmp",
  version = "*",
  dependencies = { 'L3MON4D3/LuaSnip', version = 'v2.*' },
  lazy = true,
  opts = {
    keymap = { preset = "super-tab" },
    appearance = {
      nerd_font_variant = "mono",
    },
    snippets = {
      preset = 'luasnip'
    },
    completion = {
      documentation = { auto_show = false },
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
    fuzzy = {
      implementation = "prefer_rust_with_warning",
    },
  },
  opts_extend = { "sources.default" },
}
