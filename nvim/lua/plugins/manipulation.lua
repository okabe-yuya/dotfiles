return {
  -- コメント・コメントアウト
  {
    "numToStr/Comment.nvim",
    opts = {},
  },

  -- 括弧などを自動で閉じる
  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    config = true
    -- use opts = {} for passing setup options
    -- this is equivalent to setup({}) function
  },

  -- 括弧などを操作を行うテキストオブジェクトの拡張
  -- ref: https://github.com/kylechui/nvim-surround
  {
    "kylechui/nvim-surround",
    version = "^3.0.0", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({
        -- Configuration here, or leave empty to use defaults
      })
    end
  },

  -- htmlタグを自動で閉じる
  {
    {
      "windwp/nvim-ts-autotag",
      event = "InsertEnter",
      opts = {
        opts = {
          enable_close = true,
          enable_rename = true,
          enable_close_on_slash = false,
        },
        per_filetype = {
          html = { enable_close = false },
        },
      },
    },
  }
}
