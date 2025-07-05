lua << EOF
  -- disable netrw at the very start of your init.lua
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1

  -- optionally enable 24-bit colour
  vim.opt.termguicolors = true

  -- OR setup with some options
  require("nvim-tree").setup({
    sort = {
      sorter = "case_sensitive",
    },
    view = {
      width = 30,
    },
    renderer = {
      group_empty = true,
      highlight_git = false,
    },
    filters = {
      dotfiles = false,
    },
    git = {
      enable = false,
    },
  })

  -- ファイル引数なしでNeovim起動したらnvim-treeを開く
    -- nvim-tree以外のバッファが1つだけで、かつそのバッファがnvim-treeならNeovimを終了する自動コマンド
  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
      local api = require("nvim-tree.api")
      local tab_wins = vim.api.nvim_tabpage_list_wins(0)
      if #tab_wins == 1 then
        local buf = vim.api.nvim_win_get_buf(tab_wins[1])
        local ft = vim.api.nvim_buf_get_option(buf, "filetype")
        if ft == "NvimTree" then
          vim.cmd("quit")
        end
      end
    end,
  })

  -- key mapping
  vim.keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>', { noremap = true, silent = true })
  vim.keymap.set('n', '<C-h>', ':NvimTreeFocus<CR>', { noremap = true, silent = true })
  vim.keymap.set('n', '<C-f>', ':NvimTreeFindFile<CR>', { noremap = true, silent = true })
EOF
