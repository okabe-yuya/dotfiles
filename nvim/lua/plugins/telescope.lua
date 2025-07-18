return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  lazy = true,
  keys = {
    { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Find files with Telescope" },
    { "<C-g>", "<cmd>Telescope live_grep<cr>", desc = "Live grep with Telescope" },
  },
  config = function()
    require("telescope").setup({
      defaults = {
        winblend = 100, -- 背景透過
      },
    })
  end,
}
