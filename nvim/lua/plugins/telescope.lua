return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  lazy = true,
  keys = {
    -- key mapping は VsCodeライクに設定
    { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Find files with Telescope" },
    { "<C-g>", "<cmd>Telescope live_grep<cr>", desc = "Live grep with Telescope" },
    { "<C-b>", "<cmd>Telescope buffers<cr>", desc = "Find buffers with Telescope" },

    { "<leader>g", "<cmd>Telescope resume<cr>", desc = "前回の検索結果を表示する" }
  },
  opts = {
    defaults = {
      file_ignore_patterns = {
        "node_modules",
        "%.git/",
      },
      -- ファイルを表示してからディレクトリを後述する
      path_display = {
        filename_first = {
          reverse_directories = false,
        },
      },
      -- ファイル名以外のメタ情報は表示しない
      file_browser = {
        display_stat = false,
      },
    },
  }
}
