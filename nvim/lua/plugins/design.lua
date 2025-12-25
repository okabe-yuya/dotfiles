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
    "rose-pine/neovim",
    name = "rose-pine",
    config = function()
      vim.cmd("colorscheme rose-pine")

      vim.opt.laststatus = 0
    end
  },


  {
    'Bekaboo/dropbar.nvim',
    -- optional, but required for fuzzy finder support
    dependencies = {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make'
    },
    config = function()
      local dropbar_api = require('dropbar.api')
      vim.keymap.set('n', '<Leader>l', dropbar_api.pick, { desc = 'Pick symbols in winbar' })
      vim.keymap.set('n', '<Leader>gg', dropbar_api.goto_context_start, { desc = 'Go to start of current context' })
      vim.keymap.set('n', '<Leader>vn', dropbar_api.select_next_context, { desc = 'Select next context' })
    end
  }

  -- status line
  -- {
  --   'nvim-lualine/lualine.nvim',
  --   dependencies = { 'nvim-tree/nvim-web-devicons' },
  --   config = function()
  --     -- デフォルトのステータスラインは非表示に
  --     vim.opt.showmode = false
  --
  --     require('lualine').setup {
  --       options = {
  --         theme = 'auto',
  --         disabled_filetypes = {
  --           statusline = { "NvimTree" },
  --           winbar = { 'NvimTree' },
  --         },
  --         globalstatus = true,
  --       },
  --       sections = {
  --         lualine_c = {
  --           { 'filename', path = 1 },
  --         },
  --         lualine_x = {},
  --         lualine_y = {},
  --         lualine_z = {},
  --       },
  --     }
  --   end
  -- },
}
