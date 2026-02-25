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

-- Qで終了
keymap('n', 'Q', ':<C-u>q<CR>')

-- 行を結合する（スペースは入れない)
keymap('n', 'J', 'gJ')

-- カーソル移動
-- ctrl + a で先頭に移動
keymap('n', '<C-a>', '0')

-- ctrl + e で行末に移動
keymap('n', '<C-e>', '$')

-- Ctrl + j で esc を押したのと同じ扱いにする
keymap('n', '<C-j>', '<Esc>')
keymap('i', '<C-j>', '<Esc>')
keymap('v', '<C-j>', '<Esc>')
