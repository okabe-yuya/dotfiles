return {
  "nvim-treesitter/nvim-treesitter",
  event = "VeryLazy",
  build = ":TSUpdate",
  main = "nvim-treesitter.configs",
  opts = {
    ensure_installed = {
      "javascript",
      "typescript",
      "tsx",
      "css",
      "html",
      "json",
      "yaml",
      "lua",
      "bash",
      "markdown",
      "toml",
      "vim",
      "elixir",
      "csv",
      "graphql",
      "gotmpl",
      "sql",
      "ruby",
    }
  },
  additional_vim_regex_highlighting = false,
  highlight = { enable = false },
  textsubjects = {
    enable = true,
    prev_selection = ',',
    keymaps = {
      ['.'] = 'textsubjects-smart',
      [';'] = 'textsubjects-container-outer',
      ['i;'] = 'textsubjects-container-inner',
    },
  },
  init = function()
    vim.uv.new_timer():start(300, 0, vim.schedule_wrap(function()
      vim.cmd 'TSEnable highlight'
    end))
  end,
  dependencies = {
    'RRethy/nvim-treesitter-textsubjects',
  },
}
