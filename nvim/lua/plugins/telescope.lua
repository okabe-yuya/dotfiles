local select_one_or_multi = function(prompt_bufnr)
  local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr)
  local multi = picker:get_multi_selection()
  if not vim.tbl_isempty(multi) then
    require('telescope.actions').close(prompt_bufnr)
    for _, j in pairs(multi) do
      if j.path ~= nil then
        vim.cmd(string.format('%s %s', 'edit', j.path))
      end
    end
  else
    require('telescope.actions').select_default(prompt_bufnr)
  end
end

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
      mappings = {
        i = {
          ['<CR>'] = select_one_or_multi,
        }
      },
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
