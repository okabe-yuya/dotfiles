return {
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
