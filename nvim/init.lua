require 'config.lazy'
require 'config.keymappings'
require 'config.options'
require 'config.design'

-- lazyVimに設定が依存するため、最後に読み込み
require 'lsp'
