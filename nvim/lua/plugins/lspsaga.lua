return {
  "nvimdev/lspsaga.nvim",
  lazy = true,
  config = function()
    require('lspsaga').setup({})

    vim.keymap.set("n", "K", "<cmd>Lspsaga hover_doc<CR>")
  end,
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  }
}
