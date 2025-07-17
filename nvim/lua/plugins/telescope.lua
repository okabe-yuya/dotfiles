local M = {}

function M.setup()
  local telescope = require 'telescope'

  telescope.setup {
    defaults = {
      winblend = 100,
    },
  }
end

return M