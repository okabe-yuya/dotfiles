return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  lazy = true,
  keys = {
    { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Find files with Telescope" },
    { "<C-g>", "<cmd>Telescope live_grep<cr>",  desc = "Live grep with Telescope" },
    { "<C-q>", "<cmd>Telescope buffers<cr>",    desc = "Find buffers with Telescope" },
  },
  opts = {
    defaults = {},
  }
}
