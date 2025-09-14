require 'config.lazy'
require 'config.keymappings'
require 'config.options'

vim.o.background = 'dark'
vim.cmd.colorscheme 'vscode'

-- lazyVimに設定が依存するため、最後に読み込み
require 'lsp'
