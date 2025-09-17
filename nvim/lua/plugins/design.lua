return {
  -- インデントを分かりやすく
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = {
        char = "▏",
      }
    },
  },

  -- color scheme
  {
    "navarasu/onedark.nvim",
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      require('onedark').setup {
        style = 'darker'
      }
      -- Enable theme
      require('onedark').load()
    end
  },

  -- status line
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      -- デフォルトのステータスラインは非表示に
      vim.opt.showmode = false

      require('lualine').setup {
        options = {
          theme = 'onedark',
          disabled_filetypes = {
            statusline = { "NvimTree" },
            winbar = { 'NvimTree' },
          },
          globalstatus = true,
        },
        sections = {
          lualine_x = {},
          lualine_y = {},
          lualine_z = {},
        },
      }
    end
  },

  -- command line
  -- {
  --   "folke/noice.nvim",
  --   event = "VeryLazy",
  --   opts = {
  --     -- add any options here
  --   },
  --   dependencies = {
  --     -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
  --     "MunifTanjim/nui.nvim",
  --     -- OPTIONAL:
  --     --   `nvim-notify` is only needed, if you want to use the notification view.
  --     --   If not available, we use `mini` as the fallback
  --     -- "rcarriga/nvim-notify",
  --   }
  -- }
}
