return {
  "nvimdev/lspsaga.nvim",
  config = function(_, opts)
    require('lspsaga').setup(opts)

    -- docの表示
    vim.keymap.set("n", "<leader>f", "<cmd>Lspsaga hover_doc<CR>")

    -- エラー表示
    vim.keymap.set('n', '<leader>j', "<cmd>Lspsaga diagnostic_jump_next<CR>", opts)
    vim.keymap.set('n', '<leader>k', "<cmd>Lspsaga diagnostic_jump_prev<CR>", opts)

    -- Code Action
    vim.keymap.set('n', '<leader>a', "<cmd>Lspsaga code_action<CR>", opts)

    -- Peek definition
    vim.keymap.set('n', '<leader>d', "<cmd>Lspsaga peek_type_definition<CR>", opts)
    vim.keymap.set('n', 'gd', "<cmd>:Lspsaga goto_definition<CR>", opts) -- Ctrl+Oで元の位置に戻れる
  end,
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  }
}
