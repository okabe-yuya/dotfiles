-- ファイルツリーを表示するためのプラグイン
-- oilをファイルツリーと呼ぶのか？についてはやや疑問があるが...
return {
  "stevearc/oil.nvim",
  dependencies = { { "nvim-mini/mini.icons", opts = {} } },
  lazy = false,
  opts = {
    view_options = {
      show_hidden = true,
    },
    preview_split = "right",
    keymaps = {
      -- default setting key
      ["<CR>"] = "actions.select",
      ["g?"] = { "actions.show_help", mode = "n" },

      -- Telescope のキーと競合するため、無効にしておく
      ["<C-p>"] = false,
      ["gp"] = "actions.preview",

      -- その他に default 設定にある項目
      -- 現時点では使う予定がないが、拡張性のためコメントアウトしておく
      -- ["<C-c>"] = { "actions.close", mode = "n" },
      -- ["<C-l>"] = "actions.refresh",
      -- ["-"] = { "actions.parent", mode = "n" },
      -- ["_"] = { "actions.open_cwd", mode = "n" },
      -- ["`"] = { "actions.cd", mode = "n" },
    },
  },
  use_default_keymaps = false,
  keys = {
    -- Ctrl-n で Oil 起動
    {
      "<C-n>",
      "<cmd>Oil --preview<CR>",
      desc = "Open oil explorer"
    },
  },
}
