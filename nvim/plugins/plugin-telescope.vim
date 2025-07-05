nnoremap <C-p> <cmd>Telescope find_files<cr>
nnoremap <C-g> <cmd>Telescope live_grep<cr>

lua << EOF
  local telescope = require 'telescope'

  telescope.setup {
    defaults = {
      winblend = 100,
    },
  }
EOF

