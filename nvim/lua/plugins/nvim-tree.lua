return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = true,
  keys = {
    { "<C-n>", "<cmd>NvimTreeToggle<CR>",   desc = "Toggle NvimTree" },
    { "<C-h>", "<cmd>NvimTreeFocus<CR>",    desc = "Focus NvimTree" },
    { "<C-f>", "<cmd>NvimTreeFindFile<CR>", desc = "Find file in NvimTree" },
  },
  init = function()
    -- Neovimの組み込みファイルエクスプローラーを無効にする
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
  end,
  config = function()
    require("nvim-tree").setup({
      sort = {
        sorter = "case_sensitive",
      },
      view = {
        width = 30,
        signcolumn = 'no',
      },
      renderer = {
        group_empty = true,
        highlight_git = false,
      },
      filters = {
        dotfiles = false,
        custom = {
          "^node_modules",
        },
      },
      update_focused_file = {
        enable = true,
      },
      git = {
        enable = false,
      },
    })
  end,
}
