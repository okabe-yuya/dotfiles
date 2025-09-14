return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  lazy = true,
  keys = {
    -- key mapping は VsCodeライクに設定
    { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Find files with Telescope" },
    { "<C-g>", "<cmd>Telescope live_grep<cr>",  desc = "Live grep with Telescope" },
    { "<C-b>", "<cmd>Telescope buffers<cr>",    desc = "Find buffers with Telescope" },
  },
  opts = {
    defaults = {
      file_ignore_patterns = {
        "node_modules",
        "%.git/",
      }
    },
  }
}
