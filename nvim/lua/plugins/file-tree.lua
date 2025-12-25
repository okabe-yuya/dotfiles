-- ## nvim-tree
-- return {
--   "nvim-tree/nvim-tree.lua",
--   dependencies = { "nvim-tree/nvim-web-devicons" },
--   lazy = true,
--   keys = {
--     { "<C-n>", "<cmd>NvimTreeToggle<CR>",   desc = "Toggle NvimTree" },
--     { "<C-h>", "<cmd>NvimTreeFocus<CR>",    desc = "Focus NvimTree" },
--     { "<C-f>", "<cmd>NvimTreeFindFile<CR>", desc = "Find file in NvimTree" },
--   },
--
--   init = function()
--     -- Neovimの組み込みファイルエクスプローラーを無効にする
--     vim.g.loaded_netrw = 1
--     vim.g.loaded_netrwPlugin = 1
--   end,
--
--   config = function()
--     require("nvim-tree").setup({
--       sort = {
--         sorter = "case_sensitive",
--       },
--       view = {
--         width = 35,
--         signcolumn = 'no',
--       },
--       renderer = {
--         group_empty = true,
--         highlight_git = false,
--       },
--       filters = {
--         dotfiles = false,
--         custom = {
--           "^node_modules",
--         },
--       },
--       update_focused_file = {
--         enable = true,
--       },
--       git = {
--         enable = false,
--       },
--     })
--   end,
-- }

-- ## oil
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
