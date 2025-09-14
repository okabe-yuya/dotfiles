local keymap = vim.keymap.set

-- 改行して貼り付け
keymap('n', 'P', 'o<Esc>p', { noremap = true, silent = true })

-- 貼り付けたテキストの末尾へ自動的に移動
keymap('v', 'y', 'y`]', { silent = true })
keymap('v', 'p', 'p`]', { silent = true })
keymap('n', 'p', 'p`]', { silent = true })

-- 「-」でブラックホールレジスタを指定
keymap('n', '-', '"_')

-- 画面分割
keymap('n', 'sv', ':vsplit<Return><C-w>w', { noremap = true, silent = true })
keymap('n', 'ss', ':split<Return><C-w>w', { noremap = true, silent = true })

-- ウィンドウ移動
keymap('n', 'sh', '<C-w>h', { noremap = true, silent = true })
keymap('n', 'sk', '<C-w>k', { noremap = true, silent = true })
keymap('n', 'sj', '<C-w>j', { noremap = true, silent = true })
keymap('n', 'sl', '<C-w>l', { noremap = true, silent = true })

-- qで終了、Qでマクロ
keymap('n', 'q', ':<C-u>q<CR>')
keymap('n', 'Q', 'q')

-- 行を結合する（スペースは入れない)
keymap('n', 'J', 'gJ')

-- <leader>sでファイル保存
keymap('n', '<C-s>', ':<C-u>w<CR>')
