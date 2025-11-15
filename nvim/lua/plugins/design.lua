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
