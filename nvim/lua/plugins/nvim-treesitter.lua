return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local configs = require("nvim-treesitter.configs")

    configs.setup({
      ensure_installed = {
        "tsx",
        "toml",
        "fish",
        "php",
        "json",
        "yaml",
        "swift",
        "css",
        "html",
        "lua"
      },
      sync_install = false,
      highlight = { enable = true },
      indent = { enable = true },
    })
  end,
}
