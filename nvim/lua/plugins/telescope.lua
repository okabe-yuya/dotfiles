return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  lazy = true,
  keys = {
    -- key mapping は VsCodeライクに設定
    { "<C-p>",     "<cmd>Telescope find_files<cr>", desc = "Find files" },
    { "<C-g>",     "<cmd>Telescope live_grep<cr>",  desc = "Live grep" },
    { "<C-b>",     "<cmd>Telescope buffers<cr>",    desc = "Find buffers" },
    { "<leader>r", "<cmd>Telescope resume<cr>",     desc = "前回の検索結果を表示する" },
  },
  opts = function()
    local actions = require('telescope.actions')

    return {
      defaults = {
        mappings = {
          i = {
            -- INSERTモードでもescを押したらウィンドウを閉じる
            ['<esc>'] = actions.close,
          },
        },
        file_ignore_patterns = {
          "node_modules",
          "%.git/",
          "%.claude/",
          "%.gradle/",
          "worktrees/",
        },
        path_display = { "filename_first" },
        -- 一覧を上、プレビューを下に配置 (狭いウィンドウでも preview を確保)
        layout_strategy = "vertical",
        layout_config = {
          vertical = {
            mirror = true,
            preview_height = 0.5,
          },
          width = 0.9,
          height = 0.9,
        },
      },
    }
  end,
}
