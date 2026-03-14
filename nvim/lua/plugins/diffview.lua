return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>",          desc = "Diff View" },
    { "<leader>gD", "<cmd>DiffviewClose<cr>",         desc = "Diff View Close" },
    { "<leader>gh", "<cmd>DiffviewFileHistory<cr>",   desc = "File History" },
    { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "File History (current)" },
  },
  opts = {
    hooks = {
      -- 起動時に[No Name]のバッファが作られる
      -- タブのバッファ一覧として表示されて面倒なので、diffviewの起動時に[No Name]を閉じる
      view_opened = function()
        vim.schedule(function()
          for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if vim.fn.bufname(bufnr) == "" and vim.fn.buflisted(bufnr) == 1 then
              vim.cmd("bwipeout " .. bufnr)
            end
          end
        end)
      end,
    },
  },
}
