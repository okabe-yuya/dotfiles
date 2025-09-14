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
    'Mofiqul/vscode.nvim',
    lazy = false,
    priority = 1000,
  },

  -- status line
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup {
        options = {
          theme = 'dracula',
          disabled_filetypes = {
            statusline = { "NvimTree" },
          },
        },
        sections = {
          lualine_x = {},
          lualine_y = {},
          lualine_z = {},
        }
      }
    end
  }
}
