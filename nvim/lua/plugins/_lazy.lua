-- lazy.nvim setup
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

-- install plugins
require("lazy").setup({
  -- color scheme
  { "rebelot/kanagawa.nvim", lazy = true },

  -- telescope
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    lazy = true,
    keys = {
      { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Find files with Telescope" },
      { "<C-g>", "<cmd>Telescope live_grep<cr>", desc = "Live grep with Telescope" },
    },
    config = function()
      require("plugins.telescope").setup()
    end,
  },

  -- nvim-tree
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = true,
    keys = {
      { "<C-n>", "<cmd>NvimTreeToggle<CR>", desc = "Toggle NvimTree" },
      { "<C-h>", "<cmd>NvimTreeFocus<CR>", desc = "Focus NvimTree" },
      { "<C-f>", "<cmd>NvimTreeFindFile<CR>", desc = "Find file in NvimTree" },
    },
    config = function()
      require("plugins.nvim-tree").setup()
    end,
  },

  -- 自動補完
  {
    "saghen/blink.cmp",
    version = "*",
    dependencies = { "rafamadriz/friendly-snippets" },
    lazy = true,
    opts = require("plugins.blink-cmp").opts,
    opts_extend = { "sources.default" },
  },

  -- LSP configurations
  {
    "neovim/nvim-lspconfig",
    dependencies = { 'saghen/blink.cmp' },
    lazy = true,
    config = function()
      require("plugins.lsp").config()
    end,
    event = { "BufReadPre", "BufNewFile" }, -- ファイルを開いたときに読み込む
  },

  -- 便利系
  {
    "numToStr/Comment.nvim",
    lazy = true,
    keys = {
      { 'gc', mode = { 'n', 'x' } },
      { 'gb', mode = { 'n', 'x' } },
      { 'gcc', mode = 'n' },
    },
  },

  {
    "keaising/im-select.nvim",
    lazy = true,
    config = function()
      require("plugins.im-select").setup()
    end
  },
})
